module Issuesrc

  # A tag is an annotation found in the source code of a file that holds
  # information about the issue it corresponds to, the author or assignee, a
  # label, a title for the isssue, and its position in the file.
  class Tag
    attr_reader :label
    attr_accessor :issue_id
    attr_reader :author
    attr_reader :title
    attr_accessor :file
    attr_accessor :line
    attr_accessor :begin_pos
    attr_accessor :end_pos

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

    # The string representation of the tag, to be included in the source file.
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

    # Writes the tag in its file, using its string representation.
    #
    # Also updates the tag position information depending on +offset+
    #
    # @param offsets As the tag's position information might have been outdated
    #        by other tags having been written to the file, this function needs
    #        to know how much does it need to correct its position. +offsets+
    #        is a list of pairs +(position, offset)+ that tells that at
    #        a given position a given offset has been added or substracted.
    # @return +offsets+, updated with the new offset resulting from editing the
    #         file.
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
