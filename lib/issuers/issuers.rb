module Issuesrc

  # This module holds the different classes that can be used as issuers.
  #
  # An issuer handles an external issue tracker. It retrieves, creates,
  # updates and deletes issues in an external service.
  # 
  # Every issuer must implement the interface defined in the 
  # {Issuers::IssuerInterface} class.
  module Issuers

    # This class is here for documentation only. All classes in the Issuers
    # module that want to be considered issuers need to implement this
    # interface.
    class IssuerInterface
      # @param args Command line arguments, as key => value.
      # @param config Arguments from the configuration file, as key => value.
      # @param [Issuesrc::EventLoop] event_loop An event loop that can be used
      #         to make asynchronous I/O.
      def initialize(args, config, event_loop); end

      # Loads all the open issues marked with
      # {Issuesrc::Issuers::DEFAULT_LABEL} (or the label chose in the config)
      # from the issue tracker.
      #
      # @return [Issuesrc::Issuers::Issues]
      def async_load_issues(); end

      # Opens a new issue with the information hold in +tag+. Sets the just
      # created issue ID as +tag+'s +issue_id+ attribute.
      #
      # @param [Issuesrc::Tag] tag
      # @yieldparam [Issuesrc::Tag] The passed tag, with the issue ID updated.
      def async_create_issue(tag, &block); end

      # Updates an existing issue with the information hold in +tag+.
      #
      # @param issue_id The ID of the issue that should be updated.
      # @param [Issuesrc::Tag] tag
      # @yieldparam [Issuesrc::Tag] The passed tag.
      def async_update_issue(issue_id, tag, &block); end

      # Closes an issue.
      #
      # @param issue_id The ID of the issue that should be closed.
      # @yieldparam [Issuesrc::Tag] The passed tag.
      def async_close_issue(issue_id, &block); end

      # Updates and closes a bunch of issues.
      #
      # It matches the issues that are currently open in the issue tracker with
      # the tags found in the source code. Those that are only in the issue
      # tracker are closed. Those that are in both are updated with the
      # information from the source code.
      #
      # Reports what is being done to the passed block.
      #
      # @param prev_issues An array of issues, as they are returned from
      #                    {Issuesrc::Issuers::IssuerInterface.async_load_issues}.
      # @param tags_by_issue_id
      # @yieldparam issue_id The ID of an issue.
      # @yieldparam {Issuesrc::Tag} tag The tag associated with the issue.
      # @yieldparam action Either +:updated+ or +:closed+.
      def async_update_or_close_issues(prev_issues, tags_by_issue_id, &block)
      end
    end

    # A generator of issues.
    #
    # Reads issues from the queue passed to the constructor and yields them.
    # 
    # The format of each issue is specific to a particular issuer.
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
  end
end