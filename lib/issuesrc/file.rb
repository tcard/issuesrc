module Issuesrc
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
      f = File.open(@path, 'wb')
      f.write(fbody)
      f.close()
    end

    private
    def replace_in_string(s, pos, deleted_length, new_content)
      (s[0...pos] || '') + new_content + (s[pos + deleted_length..-1] || '')
    end
  end

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
