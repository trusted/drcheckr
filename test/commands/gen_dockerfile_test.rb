# frozen_string_literal: true

require 'test_helper'
require 'drcheckr'
require 'tmpdir'
require 'fileutils'

class GenDockerfileTest < Minitest::Test
  FIXTURE_DIR = File.expand_path('../fixtures/gen_dockerfile', __dir__)

  def test_generates_dockerfile_from_template
    Dir.mktmpdir do |tmpdir|
      FileUtils.cp(File.join(FIXTURE_DIR, 'drcheckr.yml'), tmpdir)
      FileUtils.cp(File.join(FIXTURE_DIR, 'drcheckr-lock.yml'), tmpdir)
      FileUtils.mkdir_p(File.join(tmpdir, 'my_image'))
      FileUtils.cp(File.join(FIXTURE_DIR, 'my_image', 'Dockerfile.erb'), File.join(tmpdir, 'my_image'))

      Dir.chdir(tmpdir) do
        checkrfile = Drcheckr::Checkrfile.new('drcheckr.yml')
        cmd = Drcheckr::Commands::GenDockerfile.new(checkrfile, additional_vars: {})
        cmd.run!

        generated = File.read(File.join(tmpdir, 'my_image', 'Dockerfile'))
        expected = File.read(File.join(FIXTURE_DIR, 'my_image', 'Dockerfile'))

        assert_equal expected, generated
      end
    end
  end
end
