require 'issuesrc/config'
require 'em-http-request'
require 'json'
require 'set'

module Issuesrc
  module Issuers
    DEFAULT_LABEL = 'issuesrc'

    class Issues
      def initialize(queue)
        @queue = queue
        @queue_done = false
        @cache = []
      end

      def each
        i = 0
        while i < @cache.length
          yield @cache[i]
          i += 1
        end

        while !@queue_done
          @queue.pop do |issue_page|
            if issue_page == :end
              @queue_done = true
              next
            end
            issue_page.each do |issue|
              yield issue unless issue.include? 'pull_request'
            end
          end
        end
      end

    end

    class GithubIssuer
      def initialize(args, config, event_loop)
        @user, @repo = find_repo(args, config)
        @token = try_find_token(args, config)
        @event_loop = event_loop

        @issuesrc_label = try_find_issuesrc_label(args, config)
      end

      def async_load_issues()
        queue = EM::Queue.new
        async_load_issues_pages(queue, 1)
        Issues.new(queue)
      end

      def async_create_issue(tag, &block)
        save_tag(tag, :post, "/repos/#{@user}/#{@repo}/issues", &block)
      end

      def async_update_issue(issue_id, tag, &block)
        save_tag(tag, :patch, "/repos/#{@user}/#{@repo}/issues/#{issue_id}",
                 &block)
      end

      def async_close_issue(issue_id)
        ghreq(:patch, "/repos/#{@user}/#{@repo}/issues/#{issue_id}", {
          'state' => 'closed'
        }) do |req|
          yield if block_given?
        end
      end

      def async_update_or_close_issues(prev_issues, tags_by_issue_id, &block)
        updated = Set.new

        prev_issues.each do |issue|
          issue_id = issue['number'].to_s

          if tags_by_issue_id.include? issue_id
            updated.add issue_id
            tag = tags_by_issue_id[issue_id]
            make_sure_issue_exists_and_then do |exists|
              if exists
                async_update_issue(issue_id, tag) do |tag|
                  if !block.nil?
                    yield issue_id, tag, :updated
                  end
                end
              end
            end
          else
            async_close_issue(issue_id) do
              yield issue_id, nil, :closed
            end
          end
        end

        tags_by_issue_id.each do |issue_id, tag|
          if updated.include? issue_id
            next
          end
          make_sure_issue_exists_and_then do |exists|
            if exists
              async_update_issue(issue_id, tag) do |tag|
                if !block.nil?
                  yield issue_id, tag, :updated
                end
              end
            end
          end
        end
      end

      def make_sure_issue_exists_and_then
        # TODO
        yield true
      end

      private
      def find_repo(args, config)
        repo_arg = Issuesrc::Config::option_from_both(
          :repo, ['github', 'repo'], args, config, :require => true)
        repo_arg.split('/')
      end

      def try_find_token(args, config)
        Issuesrc::Config::option_from_both(
          :github_token, ['github', 'auth_token'], args, config)
      end

      def try_find_issuesrc_label(args, config)
        label = Issuesrc::Config::option_from_both(
          :issuesrc_label, ['issuer', 'issuesrc_label'], args, config)
        if label.nil?
          label = DEFAULT_LABEL
        end
        label
      end

      def async_load_issues_pages(queue, from_page)
        concurrent_pages = 1  # TODO: Configurable?

        waiting_for = concurrent_pages
        end_reached = false

        (from_page...from_page + concurrent_pages).each do |page|
          ghreq(
            :get,
            "repos/#{@user}/#{@repo}/issues?filter=all&page=#{page}" +
            "&labels=#{DEFAULT_LABEL}"
          ) do |req|
            st = req.response_header.status
            if st < 200 or st >= 300
              end_reached = true
              queue.push(:end)
            end

            if end_reached
              next
            end

            page_issues = JSON.parse(req.response)
            if page_issues.length == 0
              end_reached = true
              queue.push(:end)
            else
              queue.push(page_issues)
            end

            waiting_for -= 1
            if waiting_for == 0 and !end_reached
              async_load_issues_pages(queue, from_page + concurrent_pages)
            end
          end
        end
      end

      def save_tag(tag, method, url, &block)
        title = gen_issue_title(tag)
        body = gen_issue_body(tag)
        params = {
          'title' => title,
          'labels' => [@issuesrc_label, tag.label],
          'body' => body,
          'state' => 'open',
        }
        if !tag.author.nil?
          params['assignee'] = tag.author
        end
        ghreq(method, url, params) do |req|
          # TODO: Error handling.
          new_tag_data = JSON.parse(req.response)
          tag.issue_id = new_tag_data['number'].to_s

          if !block.nil?
            block.call tag
          end
        end
      end

      def gen_issue_title(tag)
        title = tag.title
        if title.nil? || title.length == 0
          title = "#{tag.label} at #{tag.file.path_in_repo}:#{tag.line}"
        end
        title
      end

      def gen_issue_body(tag)
        body = ""
        if tag.file.instance_of? Issuesrc::GitFile
          body = "https://github.com/#{@user}/#{@repo}" +
                 "/blob/#{tag.file.branch}/#{tag.file.path_in_repo}" +
                 "\#L#{tag.line}"
        else
          body = tag.file.path
        end
      end

      def ghreq(method, url, params=nil)
        if url[0] == ?/
          url = url[1..-1]
        end

        req_data = {
          :head => {
            'Accept' => 'application/vnd.github.v3+json'
          }
        }
        if !@token.nil?
          req_data[:head]['Authorization'] = "token #{@token}"
        end
        if !params.nil?
          req_data[:head]['Content-Type'] = 'application/json; charset=utf-8'
          req_data[:body] = JSON.generate(params)
        end

        @event_loop.async_http_request(
          method,
          "https://api.github.com/#{url}",
          req_data
        ) do |req|
          yield req if block_given?
        end
      end
    end
  end
end

