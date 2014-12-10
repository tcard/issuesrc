# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.

require 'issuesrc/version'
require 'issuesrc/config'
require 'issuesrc/tag_extractor'
require 'issuesrc/event_loop'

module Issuesrc
  DEFAULT_SOURCER = 'github'
  DEFAULT_ISSUER = 'github'
  DEFAULT_TAG_FINDERS = ['blunt']

  SOURCERS = {
    'git' => ['sourcers/git_sourcer', 'GitSourcer'],
    'github' => ['sourcers/github_sourcer', 'GithubSourcer'],
  }

  ISSUERS = {
    'github' => ['issuers/github_issuer', 'GithubIssuer'],
  }

  TAG_FINDERS = {
    'blunt' => ['tag_finders/blunt_tag_finder', 'BluntTagFinder'],
  }

  # Run issuesrc.
  def self.run(args, config)
    program = Class.new { include Issuesrc }.new
    program.set_config(args, config)
    program.init_files_offsets()

    event_loop = Issuesrc::SequentialEventLoop.new()
    sourcer = program.load_sourcer()
    tag_finders = program.load_tag_finders()
    issuer = program.load_issuer(event_loop)

    issues = issuer.async_load_issues()

    created_tags, updated_tags, closed_issues = [], [], []
    tags_by_issue_id = {}

    sourcer.retrieve_files().each do |file|
      if Issuesrc::Config.option_from_args(:verbose, args)
        puts file.path
      end

      tag_finder = program.select_tag_finder_for(file, tag_finders)
      if tag_finder.nil?
        next
      end

      tags = []
      tag_finder.find_tags(file) { |tag| tags << tag }

      tags_in_file, new_tags = program.classify_tags(tags)
      tags_by_issue_id.update(tags_in_file)

      new_tags.each do |tag|
        created_tags << tag
        issuer.async_create_issue(tag) do |tag|
          program.save_tag_in_file(tag)
        end
      end
    end

    issuer.async_update_or_close_issues(issues, tags_by_issue_id) do
    |issue_id, tag, action|
      case action
      when :updated
        program.save_tag_in_file(tag)
        updated_tags << tag
      when :closed
        closed_issues << issue_id
      end
    end

    event_loop.wait_for_pending()

    if sourcer.respond_to? :finish
      sourcer.finish(created_tags, updated_tags, closed_issues)
    end
  end

  def set_config(args, config)
    @args = args
    @config = config
  end

  attr_accessor :files_offsets

  def init_files_offsets
    @files_offsets = {}
  end

  # Creates the instance of the sourcer that should be used for the current
  # execution of issuesrc. It looks first at the :sourcer command line
  # argument, then `[sourcer] sourcer = ...` from the config file. If those are
  # not present, `DEFAULT_SOURCER` will be used. If the selected sourcer is not
  # implemented, ie. is not a key of `SOURCERS`, the execution will fail.
  def load_sourcer
    path, cls = load_component(
      ['sourcer', 'sourcer'],
      :sourcer,
      DEFAULT_SOURCER,
      SOURCERS)
    do_require(path)
    make_sourcer(cls)
  end

  def make_sourcer(cls)
    Issuesrc::Sourcers.const_get(cls).new(@args, @config)
  end

  # Like `load_sourcer`, but for the issuer. It first looks at :issuer from
  # the command line arguments, then `[issuer] issuer = ...` from the config
  # file.
  def load_issuer(event_loop)
    path, cls = load_component(
      ['issuer', 'issuer'],
      :issuer,
      DEFAULT_ISSUER,
      ISSUERS)
    do_require(path)
    make_issuer(cls, event_loop)
  end

  def make_issuer(cls, event_loop)
    Issuesrc::Issuers.const_get(cls).new(@args, @config, event_loop)
  end

  def load_component(config_key, arg_key, default, options)
    type = Config.option_from_both(arg_key, config_key, @args, @config)
    if type.nil?
      type = default
    end
    load_component_by_type(type, options)
  end

  def load_component_by_type(type, options)
    if !options.include?(type)
      Issuesrc::exec_fail 'Unrecognized sourcer type: #{type}'
    end

    options[type]
  end

  # Like `load_sourcer` but for the tag finders. It only looks at
  # `[tag_finders] tag_finders = [...]` from the config file.
  def load_tag_finders
    tag_finders = Config.option_from_config(
      ['tag_finders', 'tag_finders'], @config)
    if tag_finders.nil?
      tag_finders = DEFAULT_TAG_FINDERS
    end
    load_tag_finders_by_types(tag_finders)
  end

  def load_tag_finders_by_types(types)
    tag_extractor = load_tag_extractor()
    tag_finders = []
    types.each do |type|
      path, cls = load_component_by_type(type, TAG_FINDERS)
      do_require(path)
      tag_finders << make_tag_finder(cls, tag_extractor)
    end
    tag_finders
  end

  def load_tag_extractor
    Issuesrc::TagExtractor.new(@args, @config)
  end

  def make_tag_finder(cls, tag_extractor)
    Issuesrc::TagFinders.const_get(cls).new(tag_extractor, @args, @config)
  end

  def select_tag_finder_for(file, tag_finders)
    ret = nil
    tag_finders.each do |tag_finder|
      if tag_finder.accepts? file
        ret = tag_finder
        break
      end
    end
    ret
  end

  def classify_tags(tags)
    tags_by_issue = {}
    new_tags = []
    tags.each do |tag|
      if tag.issue_id.nil?
        new_tags << tag
      else
        tags_by_issue[tag.issue_id] = tag
      end
    end
    [tags_by_issue, new_tags]
  end

  def save_tag_in_file(tag)
    offsets = @files_offsets.fetch(tag.file.path, [])
    offsets = tag.write_in_file(offsets)
    @files_offsets[tag.file.path] = offsets
  end

  def self.exec_fail(feedback)
    raise IssuesrcError, feedback
  end

  def do_require(path)
    require path
  end

  class IssuesrcError < Exception; end
end
