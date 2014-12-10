require 'tmpdir'
require 'open3'
require 'find'
require 'issuesrc/file'
require 'issuesrc/config'
require 'ptools'

module Issuesrc
  module Sourcers
    class GitSourcer
      def initialize(args, config)
        @url = nil
        @path = nil
        @branch = nil

        url = try_find_repo_url(args, config)
        if !url.nil?
          initialize_with_url(url, args, config)
          return
        end

        path = try_find_repo_path(args, config)
        if !path.nil?
          initialize_with_path(path, args, config)
          return
        end

        init_exclude(config)
      end

      def initialize_with_url(url, args, config)
        @url = url
        init_exclude(config)
      end

      def initialize_with_path(path, args, config)
        @path = path
        init_exclude(config)
      end

      def init_exclude(config)
        @exclude = Issuesrc::Config::option_from_config(
          ['sourcer', 'exclude_files'], config)
        if @exclude.nil?
          @exclude = []
        end
      end

      def retrieve_files()
        dir = nil
        if !@url.nil?
          tmp_dir = Dir::mktmpdir
          dir = clone_repo(tmp_dir)
          @path = dir
        else
          dir = @path
        end

        Enumerator.new do |enum|
          find_all_files(dir) do |file|
            enum << file
          end
          if !@url.nil?
            FileUtils.remove_entry_secure tmp_dir
          end
        end
      end

      def finish(created_tags, updated_tags, closed_issues)
        if created_tags.empty? && closed_issues.empty?
          return
        end

        msg = make_commit_message(created_tags, updated_tags, closed_issues)
        $stderr.puts msg
        # make_commit(msg)
      end

      def make_commit(msg)
        prev_dir = Dir::pwd
        Open3.popen3("git commit -a --file -") do |fin, fout, ferr, proc|
          fin.write(msg + "\n")
          fin.close
          out = fout.read 
          err = ferr.read
          status = proc.value
          fout.close
          ferr.close
          if status.to_i != 0
            Dir::chdir(prev_dir)
            raise err
          end
        end
        Dir::chdir(prev_dir)
      end

      private
      def try_find_repo_url(args, config)
        Issuesrc::Config::option_from_both(:repo_url, ['git', 'repo'],
                                           args, config)
      end

      private
      def try_find_repo_path(args, config)
        Issuesrc::Config::option_from_both(:repo_path, ['git', 'repo_path'],
                                           args, config)
      end

      def clone_repo(dir)
        out, err, status = Open3.capture3 "git clone #{@url} #{dir}/repo"
        if status != 0
          raise err
        end
        repo_dir = dir + '/repo'
        change_branch_in_clone(repo_dir)
        repo_dir
      end

      def find_all_files(dir)
        set_branch_from_clone(dir)
        Find.find(dir) do |path|
          if FileTest.directory?(path) || File.binary?(path)
            if File.basename(path) == '.git'
              Find.prune
            end
            next
          end

          excluded = false
          @exclude.each do |exc|
            if File.fnmatch?(exc, path_in_repo(path))
              excluded = true
              next
            end
          end
          if excluded
            next
          end

          yield Issuesrc::GitFile.new(path, path_in_repo(path), @branch)
        end
      end

      def path_in_repo(path)
        path[@path.length + 1..-1]
      end

      def change_branch_in_clone(repo_dir)
        if @branch.nil?
          return
        end

        pwd = Dir::pwd
        Dir::chdir(repo_dir)
        out, err, status = Open3.capture3 "git checkout #{@branch}"
        if status != 0
          Dir::chdir(pwd)
          raise err
        end
        Dir::chdir(pwd)
      end

      def set_branch_from_clone(repo_dir)
        pwd = Dir::pwd
        Dir::chdir(repo_dir)
        out, err, status = Open3.capture3 "git rev-parse --abbrev-ref HEAD"
        if status != 0
          Dir::chdir(pwd)
          raise err
        end
        @branch = out[0..-2]
        Dir::chdir(pwd)
      end

      def make_commit_message(created_tags, updated_tags, closed_issues)
        s = "Issuesrc: Synchronize issues from source code."
        created_issues = created_tags.map { |x| x.issue_id }
        s << make_commit_message_issues("Opens", created_issues)
        s << make_commit_message_issues("Fixes", closed_issues)
      end

      def make_commit_message_issues(action, issue_ids)
        if issue_ids.empty?
          return ""
        end

        s = "\n\n"
        parts = []
        issue_ids.each do |issue_id|
          parts << "#{action} \##{issue_id}"
        end
        s << parts.join("\n")
        s
      end
    end
  end
end
