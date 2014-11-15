require 'sourcers/git_sourcer'
require 'issuesrc/config'

module Issuesrc
  module Sourcers
    class GithubSourcer < GitSourcer
      def initialize(args, config)
        begin
          user, repo = try_find_repo(args, config)
          url = "git@github.com:#{user}/#{repo}.git"
          GitSourcer.instance_method(:initialize_with_url).bind(self).call(
            url, args, config)
        rescue Exception => e
          super args, config
        end
      end

      private
      def try_find_repo(args, config)
        repo_arg = Issuesrc::Config::option_from_both(
          :repo, ['github', 'repo'], args, config)
        repo_arg.split('/')
      end
    end
  end
end
