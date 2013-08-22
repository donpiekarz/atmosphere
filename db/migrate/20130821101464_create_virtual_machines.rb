class CreateVirtualMachines < ActiveRecord::Migration
  def change
    create_table :virtual_machines do |t|
      t.string :id_at_site,               null: false
      t.string :name,                     null:false
      t.string :state,                    null:false
      t.string :ip

      t.references :compute_site,         null:false

      t.timestamps
    end

    add_foreign_key :virtual_machines, :compute_sites

    create_table :virtual_machines_appliances do |t|
      t.belongs_to :virtual_machine
      t.belongs_to :appliance
    end
  end
end