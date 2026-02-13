# frozen_string_literal: true

require 'test_helper'

class DrcheckrBinTest < Minitest::Test
  def test_binary_runs_successfully
    output = `#{bin_path} --help 2>&1`

    assert_equal 0, $?.exitstatus, "Expected bin/drcheckr to exit 0, got #{$?.exitstatus}.\nOutput:\n#{output}"
  end

  private

  def bin_path
    File.expand_path('../../bin/drcheckr', __dir__)
  end
end
