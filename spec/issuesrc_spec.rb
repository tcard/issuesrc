require_relative 'spec_helper'
require_relative '../lib/issuesrc'

describe Issuesrc do
  before :each do
    @args = {
      :arg => 'fake arg'
    }
    @config = {
      'config' => ['fake', 'config']
    }
    @obj = Class.new do
      include Issuesrc
    end.new
    @obj.send(:set_config, @args, @config)
  end

  describe '#load_sourcer' do
    it 'loads the sourcer component' do
      allow(@obj).to receive(:load_component)
        .and_return(['fake path', 'fake cls'])
      allow(@obj).to receive(:do_require)
      allow(@obj).to receive(:make_sourcer).and_return('fake sourcer')

      expect(@obj).to receive(:load_component).with(
        ['sourcer', 'sourcer'],
        :sourcer,
        Issuesrc::DEFAULT_SOURCER,
        Issuesrc::SOURCERS)
      expect(@obj).to receive(:do_require).with('fake path')
      expect(@obj).to receive(:make_sourcer).with('fake cls')

      sourcer = @obj.send(:load_sourcer)

      expect(sourcer).to be == 'fake sourcer'
    end
  end

  describe '#load_issuer' do
    it 'loads the issuer component' do
      allow(@obj).to receive(:load_component)
        .and_return(['fake path', 'fake cls'])
      allow(@obj).to receive(:do_require)
      allow(@obj).to receive(:make_issuer).and_return('fake issuer')
      
      @obj.send(:set_config, 'fake args', 'fake config')

      expect(@obj).to receive(:load_component).with(
        ['issuer', 'issuer'],
        :issuer,
        Issuesrc::DEFAULT_ISSUER,
        Issuesrc::ISSUERS)
      expect(@obj).to receive(:do_require).with('fake path')
      expect(@obj).to receive(:make_issuer).with('fake cls', 'fake event loop')

      issuer = @obj.send(:load_issuer, 'fake event loop')

      expect(issuer).to be == 'fake issuer'
    end
  end

  describe '#load_component' do
    it 'loads a required component for issuesrc' do
      component = @obj.send(:load_component,
        ['config'], :arg, 'def', {'fake arg' => 'foo'})
      expect(component).to be == 'foo'
    end

    it 'loads the default component when no option is given' do
      component = @obj.send(:load_component,
        ['fake'], :fake, 'def', {'def' => 'bar'})
      expect(component).to be == 'bar'
    end

    it 'fails when loading an unknown component' do
      expect { @obj.send(:load_component, ['fake'], :fake, 'def', {}) }
        .to raise_error(Issuesrc::IssuesrcError)
    end
  end

  describe '#load_tag_finders' do
    def test_load_tag_finders(from_config, mock_load_comp=true)
      allow(Issuesrc::Config).to receive(:option_from_config)
        .with(['tag_finders', 'tag_finders'], @config)
        .and_return(from_config)
      allow(@obj).to receive(:load_tag_extractor)
        .and_return('fake tag extractor')

      types = from_config ? from_config : Issuesrc::DEFAULT_TAG_FINDERS
      if types
        i = 1
        types.each do |v|
          if mock_load_comp
            path, cls = ["fake path #{i}", "fake cls #{i}"]
            allow(@obj).to receive(:load_component_by_type)
              .with(v, Issuesrc::TAG_FINDERS)
              .and_return([path, cls])
          else
            path, cls = @obj.send(
              :load_component_by_type, v, Issuesrc::TAG_FINDERS)
          end
          allow(@obj).to receive(:do_require)
            .with(path)
          allow(@obj).to receive(:make_tag_finder)
            .with(cls, 'fake tag extractor')
            .and_return("finder #{v}")
          i += 1
        end
      end

      @obj.send(:load_tag_finders)
    end

    it 'loads the required tag finders' do
      got = test_load_tag_finders(['fake', 'types'])
      expect(got).to be == ['finder fake', 'finder types']
    end

    it 'loads the default tag finders when no option is given' do
      got = test_load_tag_finders(nil)
      expect(got).to be == (Issuesrc::DEFAULT_TAG_FINDERS.collect do |v|
        "finder #{v}"
      end)
    end

    it 'fails when loading an unknown component' do
      expect { test_load_tag_finders(['madeup'], false) }
        .to raise_error(Issuesrc::IssuesrcError)
    end
  end

  describe '#select_tag_finder_for' do
    before :each do
      @file = instance_double('Issuesrc::FSFile', :type => 'ty')
      @tag_finders = [
        instance_double('Issuesrc::TagFinder'),
        instance_double('Issuesrc::TagFinder')
      ]
    end

    it 'returns the finder which accepts this file type' do
      allow(@tag_finders[0]).to receive(:accepts?)
        .with(@file).and_return(false)
      allow(@tag_finders[1]).to receive(:accepts?)
        .with(@file).and_return(true)

      got = @obj.select_tag_finder_for(@file, @tag_finders)

      expect(got).to be == @tag_finders[1]
    end

    it 'returns nil when no finder is found' do
      allow(@tag_finders[0]).to receive(:accepts?)
        .with(@file).and_return(false)
      allow(@tag_finders[1]).to receive(:accepts?)
        .with(@file).and_return(false)

      got = @obj.select_tag_finder_for(@file, @tag_finders)

      expect(got).to be == nil
    end
  end

  describe '#classify_tags' do
    before :each do
      @tags = [
        instance_double('Issuesrc::Tag', :issue_id => '123'),
        instance_double('Issuesrc::Tag', :issue_id => nil),
        instance_double('Issuesrc::Tag', :issue_id => '456'),
        instance_double('Issuesrc::Tag', :issue_id => nil),
      ]
    end

    it 'classifies tags between those with IDs and new ones' do
      tags_by_issue, new_tags = @obj.send(:classify_tags, @tags)
      expect(tags_by_issue).to be == {
        '123' => @tags[0],
        '456' => @tags[2],
      }
      expect(new_tags).to be == [@tags[1], @tags[3]]
    end
  end

  describe '#save_tag_in_file' do
    before :each do
      @obj.init_files_offsets()
      @tag = instance_double('Issuesrc::Tag',
          :issue_id => '123',
          :file => instance_double('Issuesrc::FSFile', :path => 'fake path'))
    end

    it 'saves a tag in its file and saves the given offset' do
      allow(@tag).to receive(:write_in_file).with([]).and_return('offsets')
      @obj.send(:save_tag_in_file, @tag)

      expect(@obj.files_offsets).to be == {
        'fake path' => 'offsets'
      }
    end
  end
end
