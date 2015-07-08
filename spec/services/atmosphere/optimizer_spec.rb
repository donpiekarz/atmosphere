require 'rails_helper'

describe Atmosphere::Optimizer do
  include VmtOnTHelpers

  before do
    Fog.mock!
  end

  let!(:fund) { create(:fund) }
  let!(:openstack) { create(:openstack_with_flavors, funds: [fund]) }
  let!(:u) { create(:user, funds: [fund]) }
  let!(:wf) { create(:workflow_appliance_set, user: u) }
  let!(:wf2) { create(:workflow_appliance_set, user: u) }
  let!(:shareable_appl_type) { create(:shareable_appliance_type) }
  let!(:tmpl_of_shareable_at) { create(:virtual_machine_template, appliance_type: shareable_appl_type, \
    tenants: [openstack]) }

  subject { Atmosphere::Optimizer.instance }

  it 'is not nil' do
    expect(subject).not_to be_nil
  end

  context 'flavor' do
    let(:appl_type) { create(:appliance_type, preference_memory: 1024, preference_cpu: 2) }
    let(:appl_vm_manager) do
      double('appliance_vms_manager',
        :can_reuse_vm? => false,
        save: true
      )
    end
    let(:amazon) { create(:amazon_with_flavors, funds: [fund]) }

    context 'is selected with appropriate architecture' do
      it 'if cheaper flavor does not support architecture' do
        t = create(:tenant)
        tmpl_64b = create(:virtual_machine_template, architecture: 'x86_64', appliance_type: appl_type, tenants: [t])
        fl_32b = create(:virtual_machine_flavor, flavor_name: 'flavor 32', cpu: 2, memory: 1024, hdd: 30, tenant: t, \
          supported_architectures: 'i386')
        fl_64b = create(:virtual_machine_flavor, flavor_name: 'flavor 64', cpu: 2, memory: 1024, hdd: 30, tenant: t, \
          supported_architectures: 'x86_64')

        fl_32b.set_hourly_cost_for(Atmosphere::OSFamily.first, 10)
        fl_64b.set_hourly_cost_for(Atmosphere::OSFamily.first, 20)

        selected_tmpl, selected_flavor = subject.select_tmpl_and_flavor([tmpl_64b])
        expect(selected_tmpl).to eq tmpl_64b
        expect(selected_flavor).to eq fl_64b
      end
    end

    context 'selection acknowledges user-tenant relationship through funds' do
      let(:u1) { create(:user) }
      let(:u2) { create(:user) }
      let(:t1) { create(:tenant) }
      let(:t2) { create(:tenant) }
      let(:f1) { create(:fund, tenants: [t1]) }
      let(:f2) { create(:fund, tenants: [t2]) }
      let(:vmt1) { create(:virtual_machine_template, tenants: [t1]) }
      let(:vmt2) { create(:virtual_machine_template, tenants: [t2]) }
      let(:atype) { create(:appliance_type, virtual_machine_templates: [vmt1, vmt2]) }

      it 'selects correct virtual machine template for each user' do
        u1.funds = [f1]
        u2.funds = [f2]
        aset1 = create(:appliance_set, user: u1)
        aset2 = create(:appliance_set, user: u2)
        a1 = create(:appliance, appliance_set: aset1, appliance_type: atype, fund: f1)
        a2 = create(:appliance, appliance_set: aset2, appliance_type: atype, fund: f2)
        opt_strategy_for_a1 = Atmosphere::OptimizationStrategy::Default.new(a1)
        opt_strategy_for_a2 = Atmosphere::OptimizationStrategy::Default.new(a2)
        tmpls1 = opt_strategy_for_a1.new_vms_tmpls_and_flavors
        tmpls2 = opt_strategy_for_a2.new_vms_tmpls_and_flavors
        expect(tmpls1.first[:template]).to eq vmt1
        expect(tmpls2.first[:template]).to eq vmt2
      end
    end

    context 'is selected optimally' do
      context 'appliance type preferences not specified' do
        it 'selects instance with at least 1.5GB RAM for public tenant' do
          appl_type = build(:appliance_type)
          tmpl = build(:virtual_machine_template, tenants: [amazon], appliance_type: appl_type)
          selected_tmpl, flavor = subject.select_tmpl_and_flavor([tmpl])
          expect(flavor.memory).to be >= 1536
        end

        it 'selects instance with 512MB RAM for private tenant' do
          appl_type = build(:appliance_type)
          tmpl = build(:virtual_machine_template, tenants: [openstack], appliance_type: appl_type)
          selected_tmpl, flavor = subject.select_tmpl_and_flavor([tmpl])
          expect(flavor.memory).to be >= 512
        end
      end

      context 'appliance type preferences specified' do
        let(:tmpl_at_amazon) { create(:virtual_machine_template, tenants: [amazon], appliance_type: appl_type) }
        let(:tmpl_at_openstack) { create(:virtual_machine_template, tenants: [openstack], appliance_type: appl_type) }

        it 'selects cheapest flavour that satisfies requirements' do
          selected_tmpl, flavor = subject.select_tmpl_and_flavor([tmpl_at_amazon, tmpl_at_openstack])
          flavor.reload

          expect(flavor.memory).to be >= 1024
          expect(flavor.cpu).to be >= 2
          all_discarded_flavors = amazon.virtual_machine_flavors + openstack.virtual_machine_flavors - [flavor]
          all_discarded_flavors.each {|f|
            f.reload
            if(f.memory >= appl_type.preference_memory and f.cpu >= appl_type.preference_cpu)
              expect(f.get_hourly_cost_for(Atmosphere::OSFamily.first) >= \
                flavor.get_hourly_cost_for(Atmosphere::OSFamily.first)).to be true
            end
          }
        end

        it 'selects flavor with more ram if prices are equal' do
          biggest_os_flavor = openstack.virtual_machine_flavors.max_by {|f| f.memory}
          optimal_flavor = create(:virtual_machine_flavor, memory: biggest_os_flavor.memory + 256, \
            cpu: biggest_os_flavor.cpu, hdd: biggest_os_flavor.hdd, tenant: amazon)
          biggest_os_flavor.set_hourly_cost_for(Atmosphere::OSFamily.first, 100)
          optimal_flavor.set_hourly_cost_for(Atmosphere::OSFamily.first, 100)
          amazon.reload
          appl_type.preference_memory = biggest_os_flavor.memory
          appl_type.save

          tmpl, flavor = subject.select_tmpl_and_flavor([tmpl_at_amazon, tmpl_at_openstack])

          expect(flavor).to eq optimal_flavor
          expect(tmpl).to eq tmpl_at_amazon
        end

        context 'preferences exceeds resources of available flavors' do
          it 'returns nil flavor' do
            appl_type.preference_cpu = 64
            appl_type.save

            tmpl, flavor = subject.select_tmpl_and_flavor([tmpl_at_amazon, tmpl_at_openstack])

            expect(flavor).to be_nil
          end
        end
      end
    end

    context 'dev mode properties' do
      let(:at) { create(:appliance_type, preference_memory: 1024, preference_cpu: 2) }
      let!(:vmt) { create(:virtual_machine_template, tenants: [amazon], appliance_type: at) }
      let(:as) { create(:appliance_set, appliance_set_type: :development, user: u) }

      let(:appl_vm_manager) do
        double('appliance_vms_manager',
          :can_reuse_vm? => false,
          save: true
        )
      end

      before do
        allow(Atmosphere::ApplianceVmsManager).to receive(:new)
          .and_return(appl_vm_manager)
      end

      context 'when preferences are not set in appliance' do
        it 'uses preferences from AT' do
          expect(appl_vm_manager).to receive(:spawn_vm!) do |_, flavor, _|
            expect(flavor.cpu).to eq 2
          end

          create(:appliance, appliance_type: at, appliance_set: as, fund: fund, tenants: Atmosphere::Tenant.all)
        end
      end

      context 'when preferences set in appliance' do
        before do
          @appl = build(:appliance, appliance_type: at, appliance_set: as, fund: fund, tenants: Atmosphere::Tenant.all)
          Atmosphere::Fund.all.each {|f| f.tenants = Atmosphere::Tenant.all}
          @appl.dev_mode_property_set = Atmosphere::DevModePropertySet.new(name: 'pref_test')
          @appl.dev_mode_property_set.appliance = @appl
        end

        it 'takes dev mode preferences memory into account' do
          expect(appl_vm_manager).to receive(:spawn_vm!) do |_, flavor, _|
            expect(flavor.memory).to eq 7680
          end
          @appl.dev_mode_property_set.preference_memory = 4000

          @appl.save!
        end

        it 'takes dev mode preferences cpu into account' do
          expect(appl_vm_manager).to receive(:spawn_vm!) do |_, flavor, _|
            expect(flavor.cpu).to eq 4
          end
          @appl.dev_mode_property_set.preference_cpu = 4

          @appl.save!
        end

        it 'takes dev mode preferences disk into account' do
          expect(appl_vm_manager).to receive(:spawn_vm!) do |_, flavor, _|
            expect(flavor.hdd).to eq 840
          end
          @appl.dev_mode_property_set.preference_disk = 600

          @appl.save!
        end
      end
    end
  end
end
