require_relative '../spec_helper'
require_relative '../../lib/issuesrc/file'

describe Issuesrc::FSFile do
  before :all do
    @obj = Issuesrc::FSFile.new('/made/up/path.txt')
  end

  it 'extracts the type from the extension' do
    expect(@obj.type).to be == 'txt'
  end

  describe '#replace_at' do
    it 'replaces in the middle of the body' do
      body = double()
      allow(body).to receive(:write).with('Lorem ipsum REPLACED sit amet')
      allow(@obj).to receive(:body).and_return(
        double(:read => 'Lorem ipsum dolor sit amet'))
      allow(@obj).to receive(:body_for_writing).and_return(body)
      expect(body).to receive(:close)

      @obj.replace_at(12, 5, 'REPLACED')
    end

    it 'replaces at the beginning of the body' do
      body = double()
      allow(body).to receive(:write).with('REPLACED ipsum dolor sit amet')
      allow(@obj).to receive(:body).and_return(
        double(:read => 'Lorem ipsum dolor sit amet'))
      allow(@obj).to receive(:body_for_writing).and_return(body)
      expect(body).to receive(:close)

      @obj.replace_at(0, 5, 'REPLACED')
    end

    it 'replaces at the end of the body' do
      body = double()
      allow(body).to receive(:write).with('Lorem ipsum dolor sit amREPLACED')
      allow(@obj).to receive(:body).and_return(
        double(:read => 'Lorem ipsum dolor sit amet'))
      allow(@obj).to receive(:body_for_writing).and_return(body)
      expect(body).to receive(:close)

      @obj.replace_at(24, 2, 'REPLACED')
    end
  end
end
