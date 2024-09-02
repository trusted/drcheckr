# frozen_string_literal: true

module Drcheckr
  class VariableLoader
    def initialize(checkrfile)
      @checkrfile = checkrfile
    end

    def load(current_context, additional_vars={})
      locked_vars = YAML.safe_load(File.read @checkrfile.lockfile_path).fetch('variables', {})

      out_context = {}
      computed = []
      @checkrfile.variables.each do |defn|
        name = defn['name'].to_sym
        if defn.key?('computed')
          computed << defn
        elsif defn.key?('value')
          out_context[name] = defn['value']
        else
          out_context[name] = locked_vars.fetch(name.to_s)
        end
      end

      computed_ctx = {}
      computed.each do |cdefn|
        name = cdefn['name'].to_sym
        expr = cdefn['computed']

        value = Tilt::ERBTemplate.new { expr }.render(OpenStruct.new current_context.merge(out_context))

        computed_ctx[name] = value
      end
      out_context.merge!(computed_ctx)

      out_context
    end
  end
end
