require_relative '../../lib/issuesrc/tag_extractor'

describe Issuesrc::TagExtractor do
  before :each do
    @tag_extractor = Issuesrc::TagExtractor.new({}, {})
  end

  it 'parses several representations OK' do
    cases = {
      'TODO()  Test ' => 'TODO: Test',
      'FIXME:Test' => 'FIXME: Test',
      'FIXME' => 'FIXME',
      'TODO ( #  1234 )Test' => 'TODO(#1234): Test',
      'BUG  (   tcard)' => 'BUG(tcard)',
      'BUG  (   tcard # 1234  ):Test   ' => 'BUG(tcard#1234): Test',
    }

    cases.each do |input, expected|
      got = @tag_extractor.extract(input)
      expect(got.to_s).to be == expected
      idempotent = @tag_extractor.extract(expected)
      expect(idempotent.to_s).to be == expected
    end
  end

  it 'returns nil when no tag is found' do
    got = @tag_extractor.extract('no tag here, sorry')
    expect(got).to be == nil
  end
end
