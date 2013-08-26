# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20130826080612) do

  create_table "appliance_configuration_instances", force: true do |t|
    t.text     "payload"
    t.integer  "appliance_configuration_template_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "appliance_configuration_instances", ["appliance_configuration_template_id"], name: "index_ac_instance_on_ac_template_id", using: :btree

  create_table "appliance_configuration_templates", force: true do |t|
    t.string   "name",              null: false
    t.text     "payload"
    t.integer  "appliance_type_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "appliance_configuration_templates", ["appliance_type_id"], name: "index_appliance_configuration_templates_on_appliance_type_id", using: :btree

  create_table "appliance_sets", force: true do |t|
    t.string   "name"
    t.integer  "priority",           default: 50,         null: false
    t.string   "appliance_set_type", default: "workflow", null: false
    t.integer  "user_id",                                 null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "appliance_sets", ["user_id"], name: "index_appliance_sets_on_user_id", using: :btree

  create_table "appliance_types", force: true do |t|
    t.string   "name",                                            null: false
    t.text     "description"
    t.boolean  "shared",            default: false,               null: false
    t.boolean  "scalable",          default: false,               null: false
    t.string   "visibility",        default: "under_development", null: false
    t.float    "preference_cpu"
    t.integer  "preference_memory"
    t.integer  "preference_disk"
    t.integer  "security_proxy_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "appliance_types", ["name"], name: "index_appliance_types_on_name", unique: true, using: :btree
  add_index "appliance_types", ["user_id"], name: "appliance_types_user_id_fk", using: :btree

  create_table "appliances", force: true do |t|
    t.integer  "appliance_set_id",                    null: false
    t.integer  "appliance_type_id",                   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "appliance_configuration_instance_id", null: false
  end

  add_index "appliances", ["appliance_configuration_instance_id"], name: "index_appliances_on_appliance_configuration_instance_id", using: :btree
  add_index "appliances", ["appliance_set_id"], name: "appliances_appliance_set_id_fk", using: :btree
  add_index "appliances", ["appliance_type_id"], name: "appliances_appliance_type_id_fk", using: :btree

  create_table "compute_sites", force: true do |t|
    t.string   "site_id"
    t.string   "name"
    t.string   "location"
    t.string   "site_type"
    t.string   "technology"
    t.string   "username"
    t.string   "api_key"
    t.string   "auth_method"
    t.string   "auth_url"
    t.string   "authtenant_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "http_mappings", force: true do |t|
    t.string   "application_protocol",     default: "http", null: false
    t.string   "url",                      default: "",     null: false
    t.integer  "appliance_id"
    t.integer  "port_mapping_template_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "http_mappings", ["appliance_id"], name: "http_mappings_appliance_id_fk", using: :btree
  add_index "http_mappings", ["port_mapping_template_id"], name: "http_mappings_port_mapping_template_id_fk", using: :btree

  create_table "port_mapping_templates", force: true do |t|
    t.string   "transport_protocol",   default: "tcp",        null: false
    t.string   "application_protocol", default: "http_https", null: false
    t.string   "service_name",                                null: false
    t.integer  "target_port",                                 null: false
    t.integer  "appliance_type_id",                           null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "port_mapping_templates", ["appliance_type_id"], name: "port_mapping_templates_appliance_type_id_fk", using: :btree

  create_table "security_policies", force: true do |t|
    t.string   "name"
    t.text     "payload"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "security_policies", ["name"], name: "index_security_policies_on_name", unique: true, using: :btree

  create_table "security_policies_users", force: true do |t|
    t.integer "user_id"
    t.integer "security_policy_id"
  end

  create_table "security_proxies", force: true do |t|
    t.string   "name"
    t.text     "payload"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "security_proxies", ["name"], name: "index_security_proxies_on_name", unique: true, using: :btree

  create_table "security_proxies_users", force: true do |t|
    t.integer "user_id"
    t.integer "security_proxy_id"
  end

  create_table "user_keys", force: true do |t|
    t.string   "name"
    t.string   "fingerprint"
    t.text     "public_key"
    t.integer  "user_id",     null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_keys", ["user_id"], name: "user_keys_user_id_fk", using: :btree

  create_table "users", force: true do |t|
    t.string   "login",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "authentication_token"
    t.string   "email",                  default: "", null: false
    t.string   "full_name"
    t.integer  "roles_mask"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["authentication_token"], name: "index_users_on_authentication_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["login"], name: "index_users_on_login", unique: true, using: :btree

  create_table "virtual_machine_templates", force: true do |t|
    t.string   "id_at_site",         null: false
    t.string   "name",               null: false
    t.string   "state",              null: false
    t.integer  "compute_site_id",    null: false
    t.integer  "virtual_machine_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "virtual_machine_templates", ["compute_site_id"], name: "virtual_machine_templates_compute_site_id_fk", using: :btree
  add_index "virtual_machine_templates", ["virtual_machine_id"], name: "virtual_machine_templates_virtual_machine_id_fk", using: :btree

  create_table "virtual_machines", force: true do |t|
    t.string   "id_at_site",                  null: false
    t.string   "name",                        null: false
    t.string   "state",                       null: false
    t.string   "ip"
    t.integer  "compute_site_id",             null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "virtual_machine_template_id"
  end

  add_index "virtual_machines", ["compute_site_id"], name: "virtual_machines_compute_site_id_fk", using: :btree
  add_index "virtual_machines", ["virtual_machine_template_id"], name: "index_virtual_machines_on_virtual_machine_template_id", using: :btree

  create_table "virtual_machines_appliances", force: true do |t|
    t.integer "virtual_machine_id"
    t.integer "appliance_id"
  end

  add_foreign_key "appliance_configuration_instances", "appliance_configuration_templates", :name => "ac_instances_ac_template_id_fk"

  add_foreign_key "appliance_configuration_templates", "appliance_types", :name => "appliance_configuration_templates_appliance_type_id_fk"

  add_foreign_key "appliance_sets", "users", :name => "appliance_sets_user_id_fk"

  add_foreign_key "appliance_types", "users", :name => "appliance_types_user_id_fk"

  add_foreign_key "appliances", "appliance_configuration_instances", :name => "appliances_appliance_configuration_instance_id_fk"
  add_foreign_key "appliances", "appliance_sets", :name => "appliances_appliance_set_id_fk"
  add_foreign_key "appliances", "appliance_types", :name => "appliances_appliance_type_id_fk"

  add_foreign_key "http_mappings", "appliances", :name => "http_mappings_appliance_id_fk"
  add_foreign_key "http_mappings", "port_mapping_templates", :name => "http_mappings_port_mapping_template_id_fk"

  add_foreign_key "port_mapping_templates", "appliance_types", :name => "port_mapping_templates_appliance_type_id_fk"

  add_foreign_key "user_keys", "users", :name => "user_keys_user_id_fk"

  add_foreign_key "virtual_machine_templates", "compute_sites", :name => "virtual_machine_templates_compute_site_id_fk"
  add_foreign_key "virtual_machine_templates", "virtual_machines", :name => "virtual_machine_templates_virtual_machine_id_fk"

  add_foreign_key "virtual_machines", "compute_sites", :name => "virtual_machines_compute_site_id_fk"
  add_foreign_key "virtual_machines", "virtual_machine_templates", :name => "virtual_machines_virtual_machine_template_id_fk"

end
