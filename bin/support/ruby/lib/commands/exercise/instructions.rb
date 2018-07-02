require_relative '../../utils/commandline'
module Exercise
  class Output < String
    class AnsibleOutput
      attr_reader :tasks, :play, :play_recap

      def initialize(string)
        @tasks = string.scan(/(TASK .*\*$\n.*)/).flatten
        @play = string.scan(/(PLAY \[.*\*$)/).flatten.first
        @play_recap = string.scan(/(PLAY RECAP.*\*$\n.*)/).flatten.first
      end
    end

    class CICOutput
      attr_reader :container_id, :cic_start_command, :cic_connect_command, :cic_stop_command

      def initialize(string)
        @container_id = chomp(string[/Starting container: (.*)/, 1])
        @cic_start_command = chomp(string[/(cic start .*)/, 1])
        @cic_connect_command = chomp(string[/(cic connect .*)/, 1])
        @cic_stop_command = chomp(string[/(cic stop .*)/, 1])
      end

      def chomp(string)
        string&.chomp
      end
    end

    def to_ansible_output
      AnsibleOutput.new(self)
    end

    def to_cic_output
      CICOutput.new(self)
    end
  end

  module Instructions

    include Commandline
    include Commandline::Output

    def cd(dir)
      Dir.chdir(dir)
      "cd #{dir}"
    end

    def path(path)
      raise "#{path} does not exit" unless File.exist?(path)
      path
    end

    def test_command(command)
      say "running: #{command}" unless quiet?
      result = @result = run(command)
      if result.error?
        say error("failed to run: #{command}\n\n#{result}")
      elsif quiet?
        output.print '.'.green
      else
        say ok("Successfully ran: #{command}")
      end

      result
    end

    def after_all_commands
      @after_all_commands ||= []
    end

    def after_all(command)
      after_all_commands << command
      command
    end

    def command_output(command)
      command command
      last_command_output
    end

    def command(command)
      result = test_command(command)
      raise CommandError if result.error?
      command
    end

    def last_command_output
      string = @result.stdout.scrub
      bytes = string.bytes.delete_if { |byte| byte == 27 }
      string = bytes.pack('U*')
      Output.new(normalise(string.chomp))
    end

    private

    def normalise(string)
      string.gsub(/\[[\d;]+m/, '')
    end
  end
end
