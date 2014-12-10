module Issuesrc

  # This module holds the different classes that can be used as sourcers.
  #
  # A sourcer handles source code. It retrieves, reads from and edits the files
  # in which tags can be found.
  # 
  # Every sourcer must implement the interface defined in the 
  # {Sourcers::SourcerInterface} class.
  module Sourcers

    # This class is here for documentation only. All classes in the Sourcers
    # module that want to be considered issuers need to implement this
    # interface.
    class SourcerInterface
      # @param args Command line arguments, as key => value.
      # @param config Arguments from the configuration file, as key => value.
      def initialize(args, config); end

      # Retrieves all the files in which there may be tags to find.
      #
      # @return [Enumerator] Enumerator of {Issuesrc::File}.
      def retrieve_files; end

      # Optional. Called when the execution of the program finishes.
      #
      # @param created_tags Array of {Issuesrc::Tag}.
      # @param updated_tags Array of {Issuesrc::Tag}.
      # @param closed_issue_ids Array of IDs, which are Strings.
      def finish(created_tags, updated_tags, closed_issue_ids); end
    end
  end
end
