# frozen_string_literal: true

module Drcheckr
  class ContextData
    def initialize(checkrfile)
      @checkrfile = checkrfile
      @data = {}
    end

    def []=(key, value)
      @data[key.to_sym] = value
    end

    def assemble(**kw)
      OpenStruct.new(to_h(**kw))
    end

    def to_h(additional_vars: {})
      cdata = @data.dup

      @checkrfile.locked_versions.each do |dep_name, version|
        cdata["#{dep_name}_version".to_sym] = VersionNumber.parse(version)
      end

      cdata.merge! VariableLoader.new(@checkrfile).load(cdata, additional_vars)

      cdata
    end
  end
end
