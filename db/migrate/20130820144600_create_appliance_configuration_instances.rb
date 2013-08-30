class CreateApplianceConfigurationInstances < ActiveRecord::Migration
  def change
    create_table :appliance_configuration_instances do |t|
      t.text :payload

      t.references :appliance_configuration_template

      t.timestamps
    end

    #autogenerated names are too long (mode than 64 characters)
    add_index :appliance_configuration_instances, :appliance_configuration_template_id, name: 'index_ac_instance_on_ac_template_id'
    add_foreign_key :appliance_configuration_instances, :appliance_configuration_templates, name: 'ac_instances_ac_template_id_fk'
  end
end