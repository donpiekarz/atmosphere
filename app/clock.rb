# require 'config/boot'
# require 'config/environment'

require_relative "../config/boot"
require_relative "../config/environment"

module Clockwork

  every(1.minute, 'monitoring.templates') do
    ComputeSite.select(:id, :name).each do |cs|
      Rails.logger.info "Creating templates monitoring task for #{cs.name}"
      VmTemplateMonitoringWorker.perform_async(cs.id)
    end
  end

  every(30.seconds, 'monitoring.vms') do
    ComputeSite.select(:id, :name).each do |cs|
      Rails.logger.info "Creating vms monitoring task for #{cs.name}"
      VmMonitoringWorker.perform_async(cs.id)
    end
  end

  every(120.minutes, 'monitoring.flavors') do
    FlavorWorker.perform_async
  end

  every(60.minutes, 'billing.bill') do
    BillingWorker.perform_async
  end

  every(60.minutes, 'billing.bill') do
    BillingWorker.perform_async
  end

  every(5.seconds, 'monitoring.http_mappings.pending') do
    HttpMappingMonitoringWorker.perform_async(:pending)
  end

  every(30.seconds, 'monitoring.http_mappings.ok') do
    HttpMappingMonitoringWorker.perform_async(:ok)
  end

  every(15.seconds, 'monitoring.http_mappings.lost') do
    HttpMappingMonitoringWorker.perform_async(:lost)
  end

end