require_relative '../spec_helper'
require_relative '../../lib/tag_finders/blunt_tag_finder'

describe Issuesrc::TagFinders::BluntTagFinder do
  before :all do
    tag_extractor = Issuesrc::TagExtractor.new({}, {})
    @obj = Issuesrc::TagFinders::BluntTagFinder.new(tag_extractor, {}, {})

    @base_file = <<EOD
This is a file with several kind of comments supposed to be caught.

/*This is a normal block of BUG code*/

<!--
TODO: Multiline should work too.
abc  BUG: Another one.
-->

Haskell has {- TODO comments like-} this.


// This should match FIXME(tcard): until the end of the line.

Also # TODO(#38): like this.
"Don't" be -- crazy TODO and # TODO(#39): mix them!

EOD
    
    @cases = {
      'madeup' => [
        # BUG(#40): Shouldn't match end of block comments.
        [97, 107, 'BUG: code*/'],
        [240, 280, 'FIXME(tcard): until the end of the line.'],
      ],
      'html' => [
        [114, 146, 'TODO: Multiline should work too.'],
        [152, 169, 'BUG: Another one.'],
      ],
      'sql' => [
        [326, 351, 'TODO: and # TODO mix them!'],
      ],
      'sh' => [
        [289, 305, 'TODO: like this.'],
        [337, 351, 'TODO: mix them!'],
      ],
      'hs' => [
        [190, 210, 'TODO: comments like-}'],
        [326, 351, 'TODO: and # TODO mix them!'],
      ],
    }
  end

  it 'finds all the expected tags for each language' do
    @cases.each do |type, expected|
      file = instance_double('Issuesrc::FSFile', :type => type)
      expect(@obj.accepts?(file)).to be == true

      allow(@obj).to receive(:get_file_body).with(file)
        .and_return(@base_file)

      tags = []
      @obj.find_tags(file) do |tag|
        expect(tag.file).to be == file
        tags << [tag.begin_pos, tag.end_pos, tag.to_s]
      end

      expect(tags).to be == expected
    end
  end
end
