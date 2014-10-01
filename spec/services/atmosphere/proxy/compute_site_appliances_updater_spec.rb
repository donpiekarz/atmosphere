require 'rails_helper'

describe Atmosphere::Proxy::ComputeSiteAppliancesUpdater do

  let(:cs) { build(:compute_site) }

  let(:finder) { double}
  let(:finder_class) { double }
  let(:updater_class) { double }

  before do
    expect(finder_class).to receive(:new).with(cs).and_return(finder)
  end

  subject { Atmosphere::Proxy::ComputeSiteAppliancesUpdater.new(cs, finder_class, updater_class) }

  it 'updates appliances with http mappings registered on compute site' do
    appl1 = double('appl1')
    appl2 = double('appl2')
    allow(finder).to receive(:find).and_return([appl1, appl2])

    updater1 = double('updater1')
    updater2 = double('updater2')
    expect(updater_class).to receive(:new).with(appl1).and_return(updater1)
    expect(updater_class).to receive(:new).with(appl2).and_return(updater2)
    expect(updater1).to receive(:update)
    expect(updater2).to receive(:update)

    subject.update
  end
end