# == Schema Information
#
# Table name: appliance_configuration_templates
#
#  id                :integer          not null, primary key
#  name              :string(255)      not null
#  payload           :text
#  appliance_type_id :integer          not null
#  created_at        :datetime
#  updated_at        :datetime
#

require 'rails_helper'

describe Atmosphere::ApplianceConfigurationTemplate do
  it { should validate_presence_of :name }
  it { should validate_presence_of :appliance_type }
  it { should belong_to :appliance_type }
  it { should have_many(:appliance_configuration_instances).dependent(:nullify) }

  describe 'name uniques' do
    let(:appliance_type1) { create(:appliance_type) }
    let(:appliance_type2) { create(:appliance_type) }
    let(:ac_template) { create(:appliance_configuration_template, appliance_type: appliance_type1) }

    it 'allows 2 identical name when appliance types are different' do
      new_ac_template = build(:appliance_configuration_template, name: ac_template.name, appliance_type: appliance_type2)
      new_ac_template.save
      expect(new_ac_template).to be_valid
    end

    it 'does not allow 2 identical names for one appliance type' do
      new_ac_template = build(:appliance_configuration_template, name: ac_template.name, appliance_type: appliance_type1)
      new_ac_template.save
      expect(new_ac_template).to_not be_valid
    end
  end

  describe '#parameters' do
    it 'returns parameters for dynamic configuration' do
      config = create(:appliance_configuration_template,
                      payload: 'dynamic #{a} #{b} #{c}')

      expect(config.parameters).to eq ['a', 'b', 'c']
    end

    it 'remote mi_ticket from params list' do
      allow(Atmosphere).to receive(:delegation_initconf_key)
        .and_return('delegation_initconf_key')

      config_with_delegation =
        create(:appliance_configuration_template,
               payload: 'dynamic #{a} #{' + "#{Atmosphere.delegation_initconf_key}}")

      expect(config_with_delegation.parameters).to eq ['a']
    end

    it 'returns empty table for static configuration' do
      static_config = create(:appliance_configuration_template,
                             payload: 'static')

      expect(static_config.parameters).to eq []
    end
  end
end
