# frozen_string_literal: true

module Drcheckr
  class VersionNumber
    attr_reader :original
    attr_reader :major, :minor, :patch

    def self.parse(value)
      new.tap { |x| x.parse(value) }
    end

    def to_s
      @original
    end

    def semver(n=3)
      mid = (["(\\d+)"] * n).join("\\.")
      /^#{mid}$/.match(@original)
    end

    def semver?(n=3)
      semver(n) != nil
    end

    def parse(value)
      @original = value

      begin
        s = no_v.split(/[-\.]/)
        @major = Integer(s[0])
        @minor = s.length > 1 ? Integer(s[1]) : nil
        @patch = s.length > 2 ? Integer(s[2]) : nil
      rescue ArgumentError
      end
    end

    def no_v
      @original.start_with?('v') ? @original[1..] : @original
    end
    alias pure no_v

    def major_minor
      "#{@major}.#{@minor}"
    end

    def major_minor_patch
      "#{@major}.#{@minor}.#{@patch}"
    end
  end
end
