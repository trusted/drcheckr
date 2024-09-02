# frozen_string_literal: true

module Drcheckr
  module Generator
    class ContainerFileGenerator
      def initialize(checkrfile, image_name, additional_vars: {})
        @image_name = image_name
        @checkrfile = checkrfile
        @additional_vars = additional_vars
      end

      def generate
        template = Tilt.new(template_path)

        context_data = ContextData.new(@checkrfile)
        context_data[:standard_banner] = make_standard_banner

        final = template.render(context_data.assemble(additional_vars: @additional_vars))

        dest_file = File.expand_path("#{@image_name}/Dockerfile")
        File.write(dest_file, final)
      end

      private

      def template_path
        File.expand_path("#{@image_name}/Dockerfile.erb")
      end

      def make_standard_banner
        header = ["GENERATED FILE, DO NOT EDIT!"]
        header << "This was generated using drcheckr"
        header << ""
        header << "Dependencies:"
        @checkrfile.locked_versions.each do |dep_name, version|
          header << " - #{dep_name}: #{version}"
        end

        header << ""
        header.map{ |x| "\# #{x}" }.join("\n")
      end
    end
  end
end
