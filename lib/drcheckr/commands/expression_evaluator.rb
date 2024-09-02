# frozen_string_literal: true

module Drcheckr
  module Commands
    class ExpressionEvaluator
      def initialize(checkrfile, additional_vars: {}, expression:)
        @checkrfile = checkrfile
        @additional_vars = additional_vars
        @expression = expression
      end

      def run!
        context_data = ContextData.new(@checkrfile)

        template = Tilt::ERBTemplate.new { @expression }
        output = template.render(context_data.assemble(additional_vars: @additional_vars))
        print output
      end
    end
  end
end
