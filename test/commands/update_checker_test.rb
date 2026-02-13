# frozen_string_literal: true

require 'test_helper'
require 'drcheckr'
require 'tmpdir'
require 'fileutils'
require 'json'

class UpdateCheckerTest < Minitest::Test
  private

  def write_config(dir, dependencies:)
    config = { 'dependencies' => dependencies }
    File.write(File.join(dir, 'drcheckr.yml'), YAML.dump(config))
  end

  def write_lockfile(dir, locked_versions:)
    lock = { 'dependencies' => locked_versions }
    File.write(File.join(dir, 'drcheckr-lock.yml'), YAML.dump(lock))
  end

  def build_checker(dir)
    checkrfile = Drcheckr::Checkrfile.new(File.join(dir, 'drcheckr.yml'))
    Drcheckr::Commands::UpdateChecker.new(checkrfile)
  end

  public

  def test_check_exits_0_when_all_up_to_date
    Dir.mktmpdir do |dir|
      write_config(dir, dependencies: [
        { 'name' => 'myapp', 'fixed_version' => '1.0.0' }
      ])
      write_lockfile(dir, locked_versions: { 'myapp' => '1.0.0' })

      checker = build_checker(dir)
      err = assert_raises(SystemExit) { checker.check! }
      assert_equal 0, err.status
    end
  end

  def test_check_exits_122_when_outdated
    Dir.mktmpdir do |dir|
      write_config(dir, dependencies: [
        { 'name' => 'myapp', 'fixed_version' => '2.0.0' }
      ])
      write_lockfile(dir, locked_versions: { 'myapp' => '1.0.0' })

      checker = build_checker(dir)
      err = assert_raises(SystemExit) { checker.check! }
      assert_equal 122, err.status
    end
  end

  def test_check_exits_1_when_no_lockfile
    Dir.mktmpdir do |dir|
      write_config(dir, dependencies: [
        { 'name' => 'myapp', 'fixed_version' => '1.0.0' }
      ])
      # no lock file written

      checker = build_checker(dir)
      err = assert_raises(SystemExit) { checker.check! }
      assert_equal 1, err.status
    end
  end

  def test_check_exits_122_when_dep_not_in_lockfile
    Dir.mktmpdir do |dir|
      write_config(dir, dependencies: [
        { 'name' => 'myapp', 'fixed_version' => '1.0.0' }
      ])
      write_lockfile(dir, locked_versions: {})

      checker = build_checker(dir)
      err = assert_raises(SystemExit) { checker.check! }
      assert_equal 122, err.status
    end
  end

  def test_check_multiple_deps_all_up_to_date
    Dir.mktmpdir do |dir|
      write_config(dir, dependencies: [
        { 'name' => 'ruby', 'fixed_version' => '3.2.2' },
        { 'name' => 'node', 'fixed_version' => '20.0.0' }
      ])
      write_lockfile(dir, locked_versions: {
        'ruby' => '3.2.2',
        'node' => '20.0.0'
      })

      checker = build_checker(dir)
      err = assert_raises(SystemExit) { checker.check! }
      assert_equal 0, err.status
    end
  end

  def test_check_multiple_deps_one_outdated
    Dir.mktmpdir do |dir|
      write_config(dir, dependencies: [
        { 'name' => 'ruby', 'fixed_version' => '3.2.2' },
        { 'name' => 'node', 'fixed_version' => '21.0.0' }
      ])
      write_lockfile(dir, locked_versions: {
        'ruby' => '3.2.2',
        'node' => '20.0.0'
      })

      checker = build_checker(dir)
      err = assert_raises(SystemExit) { checker.check! }
      assert_equal 122, err.status
    end
  end

  def with_excon_stub(response_body)
    Excon.defaults[:mock] = true
    Excon.stub({}, { body: response_body, status: 200 })
    yield
  ensure
    Excon.stubs.clear
    Excon.defaults[:mock] = false
  end

  def test_check_with_eol_source
    Dir.mktmpdir do |dir|
      write_config(dir, dependencies: [
        { 'name' => 'ruby', 'eol' => 'ruby', 'cycle' => '3.2' }
      ])
      write_lockfile(dir, locked_versions: { 'ruby' => '3.2.2' })

      body = JSON.generate([
        { 'cycle' => '3.2', 'latest' => '3.2.2' },
        { 'cycle' => '3.1', 'latest' => '3.1.4' }
      ])

      with_excon_stub(body) do
        checker = build_checker(dir)
        err = assert_raises(SystemExit) { checker.check! }
        assert_equal 0, err.status
      end
    end
  end

  def test_check_with_github_source
    Dir.mktmpdir do |dir|
      write_config(dir, dependencies: [
        { 'name' => 'tini', 'github' => 'krallin/tini' }
      ])
      write_lockfile(dir, locked_versions: { 'tini' => 'v0.19.0' })

      atom_xml = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <feed xmlns="http://www.w3.org/2005/Atom">
          <entry>
            <id>tag:github.com,2008:Repository/12345/v0.19.0</id>
          </entry>
          <entry>
            <id>tag:github.com,2008:Repository/12345/v0.18.0</id>
          </entry>
        </feed>
      XML

      with_excon_stub(atom_xml) do
        checker = build_checker(dir)
        err = assert_raises(SystemExit) { checker.check! }
        assert_equal 0, err.status
      end
    end
  end

  def test_check_with_google_chrome_source
    Dir.mktmpdir do |dir|
      write_config(dir, dependencies: [
        { 'name' => 'chrome', 'google_chrome' => 'linux/stable' }
      ])
      write_lockfile(dir, locked_versions: { 'chrome' => '117.0.5938.132' })

      body = JSON.generate({
        'versions' => [
          { 'version' => '117.0.5938.132' },
          { 'version' => '117.0.5938.92' }
        ]
      })

      with_excon_stub(body) do
        checker = build_checker(dir)
        err = assert_raises(SystemExit) { checker.check! }
        assert_equal 0, err.status
      end
    end
  end

  def test_raises_on_unknown_source_type
    Dir.mktmpdir do |dir|
      write_config(dir, dependencies: [
        { 'name' => 'mystery' }
      ])
      write_lockfile(dir, locked_versions: { 'mystery' => '1.0' })

      checker = build_checker(dir)
      assert_raises(RuntimeError) { checker.check! }
    end
  end
end
