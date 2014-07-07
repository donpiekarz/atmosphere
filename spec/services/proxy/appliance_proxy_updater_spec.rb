require 'rails_helper'

describe Proxy::ApplianceProxyUpdater do
  subject { Proxy::ApplianceProxyUpdater.new(appl) }
  let(:http) { create(:port_mapping_template, application_protocol: :http) }
  let(:https) { create(:port_mapping_template, application_protocol: :https) }
  let(:http_https) { create(:port_mapping_template, application_protocol: :http_https) }
  let(:dnat) { create(:port_mapping_template, application_protocol: :none) }

  let(:at) { create(:appliance_type, port_mapping_templates: [http, https, http_https, dnat]) }

  context 'when no port mapping template specified' do
    context 'and no VM assigned' do
      let(:appl) { create(:appliance, appliance_type: at) }
      it 'does nothing' do
        expect {
          subject.update
        }.to change { HttpMapping.count }.by(0)
      end

      context 'but http mappings exists' do
        before do
          create(:http_mapping, application_protocol: :http, appliance: appl, port_mapping_template: http)
          create(:http_mapping, application_protocol: :https, appliance: appl, port_mapping_template: https)
        end

        it 'removes all http mappings' do
          expect {
            subject.update
          }.to change { HttpMapping.count }.by(-2)
        end
      end
    end

    context 'and inactive VM assigned' do
      let(:vm) { create(:virtual_machine, state: :build, ip: nil) }
      let(:appl) { create(:appliance, appliance_type: at, virtual_machines: [vm]) }

      it 'does nothing' do
        expect {
          subject.update
        }.to change { HttpMapping.count }.by(0)
      end
    end

    context 'and active VM assigned' do
      let(:vm1) { create(:active_vm) }
      let(:vm2) { create(:active_vm) }
      let(:appl) { create(:appliance, appliance_type: at, virtual_machines: [vm1, vm2]) }

      it 'creates 4 new http mappings' do
        expect {
          subject.update
        }.to change { HttpMapping.count }.by(4)
      end

      it 'creates only missing http mappings' do
        create(:http_mapping, application_protocol: :http, appliance: appl, port_mapping_template: http)
        expect {
          subject.update
        }.to change { HttpMapping.count }.by(3)
      end

      it 'generates proxy url for http' do
        subject.update

        http_mapping = appl.http_mappings.find_by(port_mapping_template: http)

        expect(http_mapping.url).to include proxy_name(appl, http)
        expect(http_mapping.url).to start_with 'http://'
      end

      it 'generates proxy url for https' do
        subject.update

        https_mapping = appl.http_mappings.find_by(port_mapping_template: https)

        expect(https_mapping.url).to include proxy_name(appl, https)
        expect(https_mapping.url).to start_with 'https://'
      end

      it 'generates 4 jobs' do
        subject.update

        expect(Redirus::Worker::AddProxy.jobs.size).to eq 4
      end

      it 'generates jobs to the same queue' do
        allow(Sidekiq::Client).to receive(:push)

        subject.update
        http_mapping = appl.http_mappings.find_by(port_mapping_template: http)

        expect(Sidekiq::Client).to have_received(:push).exactly(4).times do |options|
          expect(options['queue']).to eq http_mapping.compute_site.site_id
        end
      end
    end
  end

  context 'when port mapping template specified' do
    let(:vm1) { create(:active_vm) }
    let(:vm2) { create(:active_vm) }
    let(:appl) do
      create(:appliance,
          appliance_type: at,
          virtual_machines: [vm1, vm2]
        )
    end

    context 'http' do
      subject { Proxy::ApplianceProxyUpdater.new(appl) }
      before { subject.update(updated: http) }

      it 'updates only one proxy' do
        expect(Redirus::Worker::AddProxy.jobs.size).to eq 1
      end

      it 'creates new proxy in redirus' do
        expect(Redirus::Worker::AddProxy).to have_enqueued_job(
          proxy_name(appl, http),
          include(worker(vm1, http), worker(vm2, http)),
          'http',
          []
        )
      end
    end

    context 'https' do
      subject { Proxy::ApplianceProxyUpdater.new(appl) }
      before { subject.update(saved: https) }

      it 'updates only one proxy' do
        expect(Redirus::Worker::AddProxy.jobs.size).to eq 1
      end

      it 'creates new proxy in redirus' do
        expect(Redirus::Worker::AddProxy).to have_enqueued_job(
          proxy_name(appl, https),
          [worker(vm1, https), worker(vm2, https)],
          'https',
          []
        )
      end
    end

    context 'when deleting PMT' do
      subject { Proxy::ApplianceProxyUpdater.new(appl) }
      before { subject.update(destroyed: https) }

      it 'does nothing' do
        expect(Redirus::Worker::AddProxy).not_to have_enqueued_job
        expect(Redirus::Worker::RmProxy).not_to have_enqueued_job
      end
    end

    context 'when PMT name changed' do
      before do
        @old_http_https = http_https.dup
        @old_http_https.id = http_https.id
        @old_http_https = @old_http_https.freeze

        http_https.service_name = "updated_name"

        subject.update(updated: http_https, old: @old_http_https)
      end

      it 'removes old redirection' do
        expect(Redirus::Worker::RmProxy).to have_enqueued_job(
          proxy_name(appl, @old_http_https), 'http')
        expect(Redirus::Worker::RmProxy).to have_enqueued_job(
          proxy_name(appl, @old_http_https), 'https')
      end
    end
  end

  context 'when in development mode' do
    let(:as) { create(:dev_appliance_set) }
    let(:vm) { create(:active_vm) }
    let(:appl) { create(:appliance, appliance_type: at, virtual_machines: [vm], appliance_set: as) }

    subject { Proxy::ApplianceProxyUpdater.new(appl) }

    it 'creates http mapping assigned into dev_mode_property_set' do
      subject.update

      http_mapping = HttpMapping.where(appliance_id: appl.id).first

      expect(http_mapping.port_mapping_template.dev_mode_property_set).to eq appl.dev_mode_property_set
    end
  end

  def proxy_name(appl, pmt)
    "#{pmt.service_name}-#{appl.id}"
  end

  def worker(vm, pmt)
    "#{vm.ip}:#{pmt.target_port}"
  end
end