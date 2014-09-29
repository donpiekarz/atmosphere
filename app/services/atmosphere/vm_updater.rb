class VmUpdater
  def initialize(site, server, updater_class = Proxy::ApplianceProxyUpdater)
    @site = site
    @server = server
    @updater_class = updater_class
  end

  def update
    perform_update! if old_enough?

    vm
  end

  private

  attr_reader :site, :server

  def perform_update!
    vm.source_template = source_template
    vm.name = server.name || '[unnamed]'
    vm.state = map_saving_state(vm, server.task_state) ||
      map_state(server.state.downcase.to_sym)
    vm.virtual_machine_flavor = vm_flavor
    update_ips if update_ips?
    vm.updated_at_site = updated_at

    # we need to check state before vm is saved
    # to get previous state
    furhter_update_requred = furhter_update_requred?

    if vm.save
      update_affected_appliances if furhter_update_requred
    else
      error
    end
  end

  def changed?
    !vm.updated_at_site || !updated_at || vm.updated_at_site < updated_at
  end

  def updated_at
    @updated_at ||= server.respond_to?(:updated) && server.updated
  end

  def old_enough?
    server.created < Air.config.childhood_age.seconds.ago
  end

  def furhter_update_requred?
    ip_changed? || state_changed_from_active? || turned_on?
  end

  def ip_changed?
    vm.state.active? && vm.ip_changed?
  end

  def state_changed_from_active?
    vm.state_was == 'active' && vm.state_changed?
  end

  def turned_on?
    vm.state_was != 'active' && vm.state.active? && !vm.ip.blank?
  end

  def update_affected_appliances
    vm.appliances.each { |appl| @updater_class.new(appl).update }
  end

  # AWS states: pending , running, shuttingdown, stopped, stopping, terminated
  # OS states: active build deleted error hard_reboot password reboot rebuild rescue resize revert_resize shutoff suspended unknown verify_resize
  def map_state(key)
    {pending: :build , running: :active, shuttingdown: :deleted, stopped: :deleted, stopping: :deleted, terminated: :deleted, active: :active, build: :build, deleted: :deleted, error: :error, hard_reboot: :hard_reboot, password: :password, reboot: :reboot, rebuild: :rebuild, rescue: :rescue, resize: :resize, revert_resize: :revert_resize, shutoff: :shutoff, suspended: :suspended, unknown: :unknown, verify_resize: :verify_resize, paused: :paused}[key] || :unknown
  end

  def map_saving_state(vm, key)
    (:saving if vm.saved_templates.count > 0) ||
      ({image_snapshot: :saving}[key.to_sym] if key)
  end

  def vm
    @vm ||= site.virtual_machines.find_or_initialize_by(id_at_site: server.id)
  end

  def source_template
    VirtualMachineTemplate.find_by(compute_site: site, id_at_site: server.image_id)
  end

  def update_ips?
    # Updating up addresses triggers additional request to
    # open stack nova api. That is why we are checking here
    # if any change occurs. We cannot stop updating the rest
    # of VM because of https://redmine.dev.cyfronet.pl/issues/3047.
    changed? && [:active, 'active', :error, 'error'].include?(vm.state)
  end

  def update_ips
    #{"vmnet"=>[{"version"=>4, "addr"=>"10.101.0.2"}]}   - ismop
    #{"private"=>[{"version"=>4, "addr"=>"10.101.0.2"}]} - vph
    vm.ip = server.public_ip_address || (server.addresses.first.last.first['addr'] if server.addresses and !server.addresses.blank?)
  end

  def vm_flavor
    VirtualMachineFlavor.where(compute_site: vm.compute_site, id_at_site: server.flavor['id']).first
  end

  def error
    Rails.logger.error "MONITORING: unable to create/update #{vm.id} virtual machine because: #{vm.errors}"
  end
end