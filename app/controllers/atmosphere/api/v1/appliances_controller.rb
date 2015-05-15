class Atmosphere::Api::V1::AppliancesController < Atmosphere::Api::ApplicationController
  before_filter :build_appliance, only: :create

  load_and_authorize_resource :appliance,
                              class: 'Atmosphere::Appliance'

  include Atmosphere::Api::Auditable

  before_filter :init_vm_search, only: :index

  respond_to :json

  def index
    respond_with @appliances.where(filter).order(:id)
  end

  def show
    respond_with @appliance
  end

  def create
    @appliance.save!
    render json: @appliance, status: :created
  end

  def update
    @appliance.update_attributes!(update_params)
    render json: @appliance
  end

  def destroy
    if Atmosphere::DestroyAppliance.new(@appliance).execute
      render json: {}
    else
      render_error @appliance
    end
  end

  def endpoints
    endpoints = Atmosphere::Endpoint.
      appl_endpoints(@appliance).
      order(:id).map do |endpoint|
        {
          id: endpoint.id,
          type: endpoint.endpoint_type,
          urls: @appliance.http_mappings.
            where(port_mapping_template_id: endpoint.port_mapping_template_id).
            map { |mapping| "#{mapping.url}/#{endpoint.invocation_path}" }
        }
      end

    render json: { endpoints: endpoints }
  end

  def action
    return reboot if reboot_action?
    return scale if scale_action?
    # place for other optimizer...

    render_json_error('Action not found', status: :bad_request)
  end

  private

  def reboot
    authorize!(:reboot, @appliance)

    @appliance.virtual_machines.each { |vm| vm.reboot }
    render json: {}, status: 200
  end

  def scale
    authorize!(:scale, @appliance)

    Atmosphere::Cloud::ScaleAppliance.
      new(@appliance, params[:scale].to_i).execute

    render json: {}, status: 200
  end

  def reboot_action?
    params.key? :reboot
  end

  def scale_action?
    params.has_key? :scale
  end

  def filter
    filter = super
    if vm_search?
      vm_ids = to_array(params[:virtual_machine_ids])
      filter[:atmosphere_deployments] = { virtual_machine_id: vm_ids}
    end
    filter
  end

  def vm_search?
    params['virtual_machine_ids']
  end

  def init_vm_search
    @appliances = @appliances.joins(:deployments) if vm_search?
  end

  def update_params
    params.require(:appliance).permit(:name, :description)
  end

  def build_appliance
    @appliance = Atmosphere::ApplianceCreator.
                  new(params.require(:appliance), delegate_auth).build
  end

  def load_admin_abilities?
    in_set_context? || super
  end

  def in_set_context?
    !params[:appliance_set_id].blank?
  end

  def model_class
    Atmosphere::Appliance
  end

  def optimizer
    Atmosphere::Optimizer.instance
  end
end
