module Issuesrc
  class Tag
    attr_reader :label
    attr_accessor :issue_id
    attr_reader :author
    attr_reader :title
    attr_reader :file
    attr_reader :line
    attr_reader :begin_pos
    attr_reader :end_pos

    def initialize(label, issue_id, author, title, file, line, 
                   begin_pos, end_pos)
      @label = label
      @issue_id = issue_id.nil? || issue_id.empty? ? nil : issue_id
      @author = author.nil? || author.empty? ? nil : author
      @title = title
      @file = file
      @line = line
      @begin_pos = begin_pos
      @end_pos = end_pos
    end

    def to_s
      ret = ""
      ret << @label
      if !@issue_id.nil? || !@author.nil?
        ret << '('
        if !@author.nil?
          ret << @author
        end
        if !@issue_id.nil?
          ret << '#' << @issue_id
        end
        ret << ')'
      end
      if !@title.nil?
        ret << ': ' << @title.strip
      end
      ret
    end

    def write_in_file(offsets)
      total_offset = 0
      offsets.each do |pos, offset|
        if pos <= @begin_pos
          total_offset += offset
        end
      end
      old_begin_pos = @begin_pos
      @begin_pos += total_offset
      @end_pos += total_offset
      file.replace_at(@begin_pos, @end_pos-@begin_pos, to_s())
      new_end_pos = @begin_pos + to_s.length
      offset = new_end_pos - @end_pos
      @end_pos = new_end_pos
      offsets << [old_begin_pos, offset]
      offsets
    end
  end
end
