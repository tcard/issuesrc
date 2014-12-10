module Issuesrc

  # This module holds the different classes that can be used as tag finders.
  #
  # An issuer handles an external issue tracker. It retrieves, creates,
  # updates and deletes issues in an external service.
  # 
  # Every tag finder must implement the interface defined in the 
  # {TagFinders::TagFinderInterface} class.
  module TagFinders

    # This class is here for documentation only. All classes in the TagFinders
    # module that want to be considered tag finders need to implement this
    # interface.
    class TagFinderInterface
      # @param tag_extractor [Issuesrc::TagExtractor]
      # @param args Command line arguments, as key => value.
      # @param config Arguments from the configuration file, as key => value.
      def initialize(tag_extractor, args, config); end

      # Tells if the tag finder can process the given file or not.
      #
      # @param [Issuesrc::File] file
      # @return [Bool]
      def accepts?(file); end

      # Finds all the tags in a file.
      #
      # Reads in the file's body looking for tags, using the instance's
      # +tag_extractor+.
      #
      # @param [Issuesrc::File] file
      # @yieldparam tag [Issuesrc::Tag]
      def find_tags(file); end
    end
  end
end