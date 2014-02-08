# This table constitutes a relational log for the billing service
# Each controller and service which performs billing operations should write to this log
# This is a standalone table - it is not directly related to any other classes in the model; instead it preserves searchable data in the form of strings
# Note: the 'actor' column should be used to specify which controller/service added the given log entry.
class CreateBillingLog < ActiveRecord::Migration
  def change
    create_table :billing_logs do |t|
      t.datetime :timestamp,        null:false
      t.string :username,           null:false, default: 'unknown user'
      t.string :appliance,          null:false, default: "unknown appliance"
      t.string :fund,               null:false, default: "unknown fund"
      t.string :actor,              null:false, default: "unknown billing actor"
      t.integer :amount_billed,     null:false, default: 0
    end
  end
end
