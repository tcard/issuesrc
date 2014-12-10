require_relative '../spec_helper'
require_relative '../../lib/issuesrc/tag'

describe Issuesrc::Tag do
  before :all do
    @file = instance_double('Issuesrc::FSFile')
    @obj = Issuesrc::Tag.new(
      'LABEL',
      'abc123',
      'theauthor',
      'The title',
      @file,
      111,
      222,
      300)
  end

  describe '#write_in_file' do
    it 'writes itself in its file with offsets' do
      offset = [[50, 10], [60, 15], [999, 999]]

      allow(@file).to receive(:replace_at)
        .with(222 + 10 + 15, 300 - 222, @obj.to_s)
      old_length = 300 - 222
      new_length = @obj.to_s.length
      expect(@obj.write_in_file(offset.clone))
        .to be == (offset + [[222, new_length - old_length]])
    end
  end
end
