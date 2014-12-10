require 'issuesrc/config'
require 'issuesrc/tag'

module Issuesrc
  TAG_EXTRACTORS = [
    {
      'regexp' => /(?<type>TODO|FIXME|BUG)\s*(\(\s*(?<author>[^)#\s]+)?\s*(#\s*(?<issue_id>[^)\s]+))?\s*\))?\s*:?\s*(?<title>[^\s].*)?/,
    }
  ]

  class TagExtractor
    def initialize(args, config)
      @extractors = Issuesrc::Config.option_from_config(
        ['tags', 'extractors'], config)
      if @extractors.nil?
        @extractors = TAG_EXTRACTORS.clone
      end

      more = Issuesrc::Config.option_from_config(
        ['tags', 'additional_extractors'], config)
      if !more.nil?
        @extractors.merge! more
      end
    end

    def extract(source)
      @extractors.each do |extr|
        tag_data = try_extractor(extr, source)
        if !tag_data.nil?
          return Issuesrc::Tag.new(
            tag_data['type'],
            tag_data['issue_id'],
            tag_data['author'],
            tag_data['title'],
            nil, nil,
            tag_data['begin_pos'],
            tag_data['end_pos']
          )
        end
      end
      nil
    end

    private
    def try_extractor(extractor, source)
      tag = nil
      if extractor.include? 'regexp'
        tag = try_regexp_extractor(extractor, source)
      end
      tag
    end

    def try_regexp_extractor(extractor, source)
      m = extractor['regexp'].match(source)
      if m.nil?
        return m
      end
      ret = {}
      m.names.each do |name|
        ret[name] = m[name]
      end
      ret['begin_pos'] = m.begin(0)
      ret['end_pos'] = ret['begin_pos'] + m.to_s.length
      ret
    end
  end
end
