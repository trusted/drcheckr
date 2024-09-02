# frozen_string_literal: true

module Drcheckr
  module Commands
    class UpdateChecker
      attr_reader :checkrfile

      def initialize(checkrfile)
        @checkrfile = checkrfile
      end

      def update!
        check_pass

        new_lock_file = checkrfile.locked_versions.dup
        @outdated_list.each do |dep_name|
          latest_version = @all_versions[dep_name].first
          puts "Will update #{dep_name} to #{latest_version}"
          new_lock_file[dep_name] = latest_version
        end

        if @outdated_list.empty?
          puts "Everything up to date, no action needed!"
          return
        end
        puts "Updating #{@outdated_list.length} dependencies"

        dest_file = checkrfile.lockfile_path
        data = YAML.dump({ 'dependencies' => new_lock_file })
        File.write(dest_file, data)
        puts "Wrote new dependencies to #{dest_file}"
      end

      def check!
        if !checkrfile.lockfile?
          puts "Lock file not present, can't check"
          exit 1
        end

        check_pass

        exit(0) if @outdated_list.empty?

        puts("Found #{@outdated_list.length} outdated dependencies")
        exit(122)
      end

      private

      def check_pass
        @all_versions = {}
        @outdated_list = []
        checkrfile.dependencies.each do |defn|
          m = defn.key?('github') ? 'github' : nil
          m ||= defn.key?('fixed_version') ? 'fixed_version' : nil
          m ||= defn.key?('google_chrome') ? 'google_chrome' : nil
          m ||= defn.key?('eol') ? 'eol' : nil

          if !m
            raise "Can't track dependency: #{defn}"
          else
            send("update_check_#{m}", defn)
          end
        end
      end

      def finish_check_dep_version(defn, versions)
        undefined = Object.new
        dep_name = defn['name']

        @all_versions[dep_name] = versions

        curr_version = (checkrfile.locked_versions || {})[dep_name]
        if !curr_version
          puts "No lock for dependency '#{dep_name}'"
          curr_version = undefined
        end

        latest_version = versions[0]
        if curr_version != latest_version
          @outdated_list << dep_name

          puts "Updates available for #{dep_name}!"
          puts "\tCurrent version: #{curr_version == undefined ? '<undefined>' : curr_version}"
          puts "\tLatest version: #{latest_version}"
        else
          puts "Dependency #{dep_name} is up to date"
        end
      end

      def update_check_fixed_version(defn)
        dep_name = defn['name']
        version = defn['fixed_version']
        puts "Skip check for #{dep_name}, fixed at #{version}"

        finish_check_dep_version(defn, [version])
      end

      def update_check_google_chrome(defn)
        platform, channel = defn['google_chrome'].split('/')
        channel ||= 'stable'
        resp = Excon.get("https://versionhistory.googleapis.com/v1/chrome/platforms/#{platform}/channels/#{channel}/versions")
        data = JSON.parse(resp.body)
        versions = data['versions'].map{ |x| x['version'] }
        finish_check_dep_version(defn, versions)
      end

      def update_check_eol(defn)
        name = defn['eol']
        cycle = defn['cycle']

        resp = Excon.get("https://endoflife.date/api/#{name}.json")
        data = JSON.parse(resp.body)
        data.select! { |x| x['cycle'] == cycle } if cycle

        versions = data.map { |x| x['latest'] }
        finish_check_dep_version(defn, versions)
      end

      def update_check_github(defn)
        dep_name = defn['name']
        repo_slug = defn['github']
        puts "GH check #{dep_name}"

        url = "https://github.com/#{repo_slug}/releases.atom"
        resp = Excon.get(url, {
          headers: {
            'User-Agent' => "drcheckr/#{Drcheckr::VERSION}",
            'Accept' => 'application/atom+xml',
          }
        })

        doc = Nokogiri::XML(resp.body)
        versions = []
        doc.css('entry').each do |entry|
          id = entry.css('id').text.strip
          version = id.split('/').last

          # puts "\t version |#{version}|"
          versions << version
        end

        finish_check_dep_version(defn, versions)
      end
    end
  end
end
