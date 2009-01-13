
# http://www.ruby-doc.org/stdlib/libdoc/observer/rdoc/index.html


require 'stella/cli/base'

module Stella
  
    
  # Stella::CLI
  #
  # The is the front-end class for the command-line implementation. The stella script
  # creates an instance of this class which is the glue between the command-line
  # and the Stella command classes. 
  # Note: All Stella::CLI classes are autoloaded and they add themselves to @@commands. 
  class CLI
    
    # Auto populated with 'command' => Stella::CLI::[class] by each cli class on 'require'.
    @@commands = {}
    
    attr_reader :command_name
    attr_reader :options
    attr_reader :logger
    attr_reader :stella_arguments
    attr_reader :command_arguments

    
    def initialize(arguments=[], stdin=nil)
      @arguments = arguments
      @stdin = stdin
      
      @options = OpenStruct.new
      @options.verbose = 0
      @options.data_path = 'stella'
      @options.agents = []
      
      @stella_arguments = []
      @command_arguments = []
      
      process_arguments
      process_options
      
    end
    
    def commands
      @@commands
    end
    
    def run
      
      unless (@command_name)
        process_options(:display)
        exit 0
      end
          
      # Pull the requested command object out of the list
      # and tell it what shortname that was used to call it.
      command = @@commands[@command_name].new(@command_name)
      
      # Give the command object access to the runtime options and arguments
      command.stella_options = @options
      command.arguments = @command_arguments
      command.working_directory = @options.data_path
      
      command.run
      
    rescue => ex
      Stella::LOGGER.error(ex)
    end
    
    
      protected
        
        
        # process_arguments
        #
        # Split the arguments into stella args and command args
        # i.e. stella -H push -f (-H is a stella arg, -f is a command arg)
        # True if required arguments were provided
        def process_arguments

          @command_name = nil     
          @arguments.each do |arg|
            if (@@commands.has_key? arg)
              @command_name = arg 
              index = @arguments.index(@command_name)
              @command_arguments = @arguments[index + 1..@arguments.size] 
              @stella_arguments = @arguments[0..index - 1] if index > 0
              break
            end
          end
          
          @stella_arguments = [] unless @stella_arguments
          @command_arguments = [] unless @command_arguments 

          # If there's no command we'll assume all the options are for Stella
          unless @command_name
            @stella_arguments = @arguments
            @arguments = []
          end

        end

        # process_options
        #
        # Handle the command-line options for stella. Note: The command specific
        # options are handled by the command/*.rb classes
        # display:: When true, it'll print out the options and not parse the arguments
        def process_options(display=false)

          opts = OptionParser.new 
          opts.banner = Stella::TEXT.msg(:option_help_usage)
          opts.on Stella::TEXT.msg(:option_help_preamble, @@commands.keys.sort.join(', '))

          opts.on(Stella::TEXT.msg(:option_help_options_title))
          opts.on('-V', '--version', Stella::TEXT.msg(:option_help_version)) do
            output_version
            exit 0
          end
          opts.on('-h', '--help', Stella::TEXT.msg(:option_help_help)) { puts opts; exit 0 }
          opts.on('-F', '--force', Stella::TEXT.msg(:option_help_force)) { |v| @options.force = true }

          opts.on('-v', '--verbose', Stella::TEXT.msg(:option_help_verbose)) do
            
            @options.verbose ||= 0
            @options.verbose += 1 
          end
          opts.on('-q', '--quiet', Stella::TEXT.msg(:option_help_quiet))   do
            @options.quiet = true 
          end
          
          # Overhead is interesting for development and auditing but we're not
          # currently tracking this. It needed to be re-implemented from scratch
          # so we'll redo this soon. It's also useful for comparing Ruby/JRuby/IronRuby
          #opts.on('--overhead', String, Stella::TEXT.msg(:option_help_overhead)) do
          #  @options.showoverhead = true 
          #end
          
          opts.on('-O', '--stdout', Stella::TEXT.msg(:option_help_stdout)) do
            @options.stdout = true 
          end
          opts.on('-E', '--stderr', Stella::TEXT.msg(:option_help_stderr)) do
            @options.stdout = true 
          end
          
          opts.on('-m', '--message=M', String, Stella::TEXT.msg(:option_help_message)) do |v| 
            @options.message = v.to_s 
          end
          opts.on('-s', '--sleep=N', Float, Stella::TEXT.msg(:option_help_sleep)) do |v|
            @options.sleep = v.to_f 
          end

          # Ramp up, establish default and enforce limits
          opts.on('-r [R,U]', '--rampup', String, Stella::TEXT.msg(:option_help_rampup)) do |v| 
            amount = (v) ? Stella::Util::expand_str(v) : [10,100]
            amount[0] = MathUtil.enforce_limit(amount[0].to_i, 1, 100)
            amount[1] = MathUtil.enforce_limit((amount[1]) ? amount[1].to_i : 0, (amount[0]*2), 1000)
            @options.rampup = amount
          end

          opts.on('-x', '--repetitions=N', Integer, Stella::TEXT.msg(:option_help_testreps)) do |v| 
            @options.repetitions = MathUtil.enforce_limit(v,1,99)
          end

          opts.on('-w [N]', '--warmup', Float, Stella::TEXT.msg(:option_help_warmup, 0.1)) do |v|
            @options.warmup = MathUtil.enforce_limit(((v) ? v : 0), 0.1, 1)
          end

          opts.on('-a', '--agent=[S]', String, Stella::TEXT.msg(:option_help_agent)) do |v| 
            @options.agents ||= []
            agent_ary = Stella::Util::expand_str(v || 'random')
            @options.agents.push(agent_ary)
          end
 
          opts.on('-d', '--datapath=S', String, Stella::TEXT.msg(:option_help_datapath, ".#{File::SEPARATOR}stella")) do |v| 
            @options.data_path = v.to_s 
          end
          opts.on('-f', '--format=S', String, Stella::TEXT.msg(:option_help_format)) do |v| 
            @options.format = v.to_s 
          end
          
          # This is used for printing the help from other parts of this class
          if display
            Stella::LOGGER.info opts
            return
          end

          # This applies the configuration above to the arguments provided. 
          # It also removes the discovered options from @stella_arguments
          # leaving only the unnamed arguments. 
          opts.parse!(@stella_arguments)

          # Quiet supercedes verbose
          @options.verbose = 0 if @options.quiet
          
          
          # This outputs when debugging is enabled. 
          dump_inputs
          
          
        rescue OptionParser::InvalidOption => ex
          # We want to replace this text so we grab just the name of the argument
          badarg = ex.message.gsub('invalid option: ', '')
          raise InvalidArgument.new(badarg)
        end

        #
        # Process data sent to STDIN (a pipe for example). 
        # We assume each line is a URI and add it to @arguments.
        def process_standard_input
          return if @stdin.tty?   # We only want piped data

          while !@stdin.eof? do
            line = @stdin.readline
            line.chomp!
            @arguments << line
          end

        end
        
        def output_version
          Stella::LOGGER.info(:cli_print_version, Stella::VERSION.to_s)
        end
        
        def dump_inputs

          #ENV.each_pair do |n,v|
          #  Stella::LOGGER.debug("ENV[#{n}]=#{v}")
          #end

          Stella::LOGGER.debug("Commands (#{@command_name}): #{@@commands.keys.join(',')}")

          
          Stella::LOGGER.debug("Options: ")
          @options.marshal_dump.each_pair do |n,v|
            v = [v] unless v.is_a? Array
            Stella::LOGGER.debug("  #{n} = #{v.join(',')}")
          end

          Stella::LOGGER.debug("Stella Arguments: #{@stella_arguments.join(',')}")
          Stella::LOGGER.debug("Command Arguments: #{@command_arguments.join(',')}" )
        end
  end
end

# Autoload CLI classes. These classes add themselves to the class variable @@commands. 
begin
  previous_path = ""
  cli_classes = Dir.glob(File.join(STELLA_HOME, 'lib', 'stella', 'cli', "*.rb"))
  cli_classes.each do |path|
    previous_path = path
    require path
  end
rescue LoadError => ex
  Stella::LOGGER.info("Error loading #{previous_path}: #{ex.message}")
end


