# frozen_string_literal: true

module Drcheckr
  module Commands
    class GenDockerfile
      attr_reader :checkrfile
      attr_reader :params

      def initialize(checkrfile, additional_vars:)
        @checkrfile = checkrfile
        @additional_vars = additional_vars
      end

      def run!
        unless @checkrfile.lockfile?
          puts "No lockfile found, aborting"
          exit 1
        end

        missing_version = @checkrfile.dependencies.map{ |x| x['name'] } - @checkrfile.locked_versions.keys
        unless missing_version.empty?
          puts "Missing versions for the following dependencies:"
          missing_version.each do |dep_name|
            puts " - #{dep_name}"
          end
          puts "Can't proceed, aborting."
          exit 1
        end

        puts "Will generate the following images:"
        @checkrfile.images.each do |img|
          puts "- #{img['name']}"
        end

        @checkrfile.images.each do |img|
          image = img['name']
          generator = Generator::ContainerFileGenerator.new(@checkrfile, image)
          generator.generate
        end
      end
    end
  end
end
