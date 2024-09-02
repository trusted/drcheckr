# frozen_string_literal: true

module Drcheckr
  class Checkrfile
    attr_reader :path

    def initialize(path)
      @path = path
    end

    def lockfile?
      File.file?(lockfile_path)
    end

    def full_path
      @full_path ||= begin
        path = @path
        path = "#{path}/.drcheckr.yml" if File.directory?(path)
        File.expand_path(path)
      end
    end

    def lockfile_path
      @lock_file_name ||= begin
        base = File.basename(full_path)
        ext = File.extname(base)
        prefix = base[0..(-ext.length-1)]
        lock_fn = "#{prefix}-lock#{ext}"
        File.expand_path(File.join full_path, "..", lock_fn)
      end
    end

    def variables
      @variables ||= begin
        YAML.safe_load(File.read full_path).fetch('variables', [])
      end
    end

    def images
      @images ||= begin
        YAML.safe_load(File.read full_path).fetch('images')
      end
    end

    def dependencies
      @dependencies ||= begin
        YAML.safe_load(File.read full_path).fetch('dependencies')
      end
    end

    def locked_versions
      return nil unless lockfile?

      @locked_versions ||= begin
        YAML.safe_load(File.read lockfile_path).fetch('dependencies')
      end
    end
  end
end
