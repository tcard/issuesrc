module Issuesrc
  # This class is here for documentation only. All classes in the Sourcers
  # module that want to be considered issuers need to implement this
  # interface.
  class FileInterface
    # @return The type of the file as a file extension.
    def type; end

    # @return [IO] The body of the file.
    def body; end

    # Replaces part of the body of the file, and saves it.
    #
    # @param pos Position from the beginning of the body in which the new
    #        content starts.
    # @param old_content_length Length of previous content that should be
    #        replaced.
    # @param new_content A string that will be written in +pos+ at the file.
    def replace_at(pos, old_content_length, new_content); end
  end

  # A file from the filesystem.
  class FSFile
    attr_reader :type
    attr_reader :path

    def initialize(path)
      @path = path
      @type = File.extname(path).slice(1..-1)
    end

    def body
      File.open(@path, 'r')
    end

    def replace_at(pos, old_content_length, new_content)
      fbody = body.read
      fbody = replace_in_string(fbody, pos, old_content_length, new_content)
      f = body_for_writing()
      f.write(fbody)
      f.close()
    end

    private
    def replace_in_string(s, pos, deleted_length, new_content)
      (s[0...pos] || '') + new_content + (s[pos + deleted_length..-1] || '')
    end

    def body_for_writing
      File.open(@path, 'wb')
    end
  end

  # A file from the filesystem that is indexed in a Git repository.
  class GitFile < FSFile
    attr_reader :repo
    attr_reader :path_in_repo
    attr_reader :branch

    def initialize(path, path_in_repo, branch)
      super(path)
      @path_in_repo = path_in_repo
      @branch = branch
    end
  end
end
