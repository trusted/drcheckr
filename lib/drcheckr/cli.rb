# frozen_string_literal: true

module Drcheckr
  class Cli
    def self.start(args)
      new(args).run
    end

    def initialize(args)
      @args = args
      @options = {
        checkrfile_path: nil,
        variables: {}
      }
    end

    def run
      command = nil
      inline_args = []

      loop do
        str = @args.shift
        break unless str

        if str == 'help' || str == '--help'
          print_help
          exit(0)
        end

        if str == '--set'
          name, value = @args.shift.split('=', 2)
          @options[:variables][name.to_sym] = value
        end

        if command
          if command == 'expr'
            inline_args << str
          else
            puts "Error: can't run multiple commands at once."
            print_help
            exit(1)
          end
        else
          command = str
        end
      end

      unless command
        puts "Error: no command was specified"
        print_help
        exit(1)
      end

      case command
      when 'check'
        update_check
      when 'gen'
        gen_dockerfile
      when 'update'
        update_lockfile
      when 'expr'
        print_expression(inline_args)
      else
        puts "Error: unrecognized command: #{command}"
        print_help
        exit(1)
      end
    end

    private

    def print_help
      puts "Usage: drcheckr <command> [options]"
      puts "\nAvailable commands:"
      puts " check - Checks whether dependencies are up to date"
      puts " update - Like check, but persists new versions to the lock file"
      puts " gen - Generates Dockerfile from existing lock file"
      puts " expr <expression> - Evaluates and prints the given expression"
      puts "\nOptions:"
      puts " --set var=value - Can be used multiple times. Sets variable to the given value"
    end

    def checkrfile_path
      @options[:checkrfile_path] || ENV.fetch('CHECKRFILE', 'drcheckr.yml')
    end

    def update_lockfile
      c = Drcheckr::Commands::UpdateChecker.new(Checkrfile.new(checkrfile_path))
      c.update!
    end

    def update_check
      c = Drcheckr::Commands::UpdateChecker.new(Checkrfile.new(checkrfile_path))
      c.check!
    end

    def print_expression(args)
      if args.length != 1
        puts "\"expr\" command expects one argument, but #{args.length} were given."
        puts "aborting."
        exit(1)
      end

      c = Drcheckr::Commands::ExpressionEvaluator.new(Checkrfile.new(checkrfile_path),
        additional_vars: @options[:variables], expression: args.first)
      c.run!
    end

    def gen_dockerfile
      c = Drcheckr::Commands::GenDockerfile.new(Checkrfile.new(checkrfile_path),
        additional_vars: @options[:variables])
      c.run!
    end
  end
end
