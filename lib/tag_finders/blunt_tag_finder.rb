require 'issuesrc/tag'

module Issuesrc
  module TagFinders

    # A tag finder that doesn't do any parsing; it just bluntly traverses the
    # source code looking for things that look like comments.
    #
    # It tries to skip comments inside strings.
    class BluntTagFinder
      DEFAULT_COMMENT_MARKERS = [['//', "\n"], ['/*', '*/']]
      DEFAULT_STRING_MARKERS = ['"', "'"]

      COMMENTS_BY_LANG = {
        'php' => [['//', "\n"], ['/*', '*/'], ['#', "\n"]],
        'html' => [['<!--', '-->']],
        'sql' => [['--', "\n"]],
        'sh' => [['#', "\n"]],
        'hs' => [['--', "\n"], ['{-', '-}']],
        'py' => [['#', "\n"]],
        'rb' => [['#', "\n"]],
        'clj' => [[';', "\n"]],
        'coffee' => [['#', "\n"]],
      }

      STRINGS_BY_LANG = {
        'go' => ['"', "'", '`'],
        'rs' => ['"'],
        'hs' => ['"'],
      }

      def initialize(tag_extractor, args, config)
        @tag_extractor = tag_extractor
      end

      def accepts?(file)
        true
      end

      def find_tags(file)
        find_comments(file) do |comment, nline, pos|
          # A tag extractor extracts from a single line, whereas comments may
          # span several lines.
          nline_offset = 0
          comment.split("\n").each do |line|
            tag = @tag_extractor.extract(line)
            if !tag.nil?
              tag.file = file
              tag.line = nline + nline_offset
              tag.begin_pos += pos
              tag.end_pos += pos
              yield tag
            end
            pos += line.length + 1
            nline_offset += 1
          end
        end
      end

      private
      def find_comments(file)
        comment_markers, string_markers = decide_markers(file)
        body = get_file_body(file)
        comment_finder = CommentFinder.new(body, comment_markers, string_markers)
        pos = 0

        comment_finder.each do |comment, nline, pos|
          yield comment, nline, pos
        end
      end

      def decide_markers(file)
        [
          COMMENTS_BY_LANG.fetch(file.type, DEFAULT_COMMENT_MARKERS),
          STRINGS_BY_LANG.fetch(file.type, DEFAULT_STRING_MARKERS),
        ]
      end

      def get_file_body(file)
        file.body.read.force_encoding('BINARY') # TTODO(#26): Use less memory here.      end

      class CommentFinder
        def initialize(body, comment_markers, string_markers)
          @body = body
          @comment_markers = comment_markers
          @string_markers = string_markers

          @pos = 0
          @nline = 1
        end

        def each
          state = :init
          while !@body.empty?
            case state
            when :init
              consumed, state = consume_init()
              @pos += consumed
            when :string
              consumed, state = consume_string()
              @pos += consumed
            when :comment
              nline = @nline
              lex, consumed, state = read_comment()
              yield [lex, nline, @pos]
              @pos += consumed
            end
          end
        end

        private
        def consume_init
          consumed = 0
          next_state = nil
          while !@body.empty?
            next_state = peek_next_state()
            if next_state != :init
              break
            end
            consumed += consume_body(1)
          end
          [consumed, next_state]
        end

        def consume_string
          lex, consumed, state = read_delimited(@string_markers)
          [consumed, state]
        end

        def read_comment
          read_delimited(@comment_markers)
        end

        def read_delimited(markers)
          marker_i, consumed = state_boundary(markers, :begin)
          lex = @body[0...consumed]
          consume_body(consumed)

          _, consumed_end = state_boundary(markers, :end, marker_i)
          while !@body.empty? && consumed_end.nil?
            lex << @body[0]
            consumed += consume_body(1)
            _, consumed_end = state_boundary(markers, :end, marker_i)
          end

          if !consumed_end.nil?
            lex << @body[0...consumed_end]
            consumed += consume_body(consumed_end)
          end

          [lex, consumed, peek_next_state()]
        end

        def peek_next_state()
          if !state_boundary(@comment_markers, :begin).nil?
            :comment
          elsif !state_boundary(@string_markers, :begin).nil?
            :string
          else
            :init
          end
        end

        def state_boundary(markers, begin_or_end, marker_i=nil)
          if @body.nil?
            nil
          end

          i = 0
          markers.each do |marker|
            if !marker_i.nil? && i != marker_i
              i += 1
              next
            end
            if marker.instance_of? Array 
              marker = marker[begin_or_end == :begin ? 0 : 1]
            end
            if @body.start_with? marker
              return [i, marker.length]
            end
            i += 1
          end
          nil
        end

        def consume_body(n)
          l = @body.length
          @nline += @body[0...n].count "\n"
          @body = @body[n..-1] || ''
          l - @body.length
        end
      end
    end
  end
end
