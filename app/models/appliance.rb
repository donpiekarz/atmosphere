# == Schema Information
#
# Table name: appliances
#
#  id                                  :integer          not null, primary key
#  appliance_set_id                    :integer          not null
#  appliance_type_id                   :integer          not null
#  created_at                          :datetime
#  updated_at                          :datetime
#  appliance_configuration_instance_id :integer          not null
#

class Appliance < ActiveRecord::Base

  belongs_to :appliance_set
  belongs_to :appliance_type
  belongs_to :appliance_configuration_instance

  validates_presence_of :appliance_set, :appliance_type, :appliance_configuration_instance

  has_many :http_mappings, dependent: :destroy
  has_and_belongs_to_many :virtual_machines

  after_destroy :remove_appliance_configuration_instance_if_needed

  private

  def remove_appliance_configuration_instance_if_needed
    if appliance_configuration_instance.appliances.blank?
      appliance_configuration_instance.destroy
    end
  end
end
