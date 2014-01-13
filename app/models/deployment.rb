# Deployments provide a m:n link between appliances and virtual machines.
class Deployment < ActiveRecord::Base
  extend Enumerize

  belongs_to :appliance
  belongs_to :virtual_machine
  
  before_destroy :generate_proxy_conf
  
  private

  def generate_proxy_conf
    ComputeSite.with_deployment(self).each do |cs|
      ProxyConfWorker.regeneration_required(cs)
    end
  end

end