require "option_parser"

module Krystal


  module CLI


    class Runner

      @config      : FConfig
      @argv        : Array(String)
      @passthrough : Array(String)

      #------------------------------------------------------------------------

      private macro declare_options ( **options )
        {% for name, meta in options %}
          property {{name}} : {{meta[0]}} = {{meta[4]}}
        {% end %}

        def bind_options! ( opts : OptionParser ) : Nil
          {% for name, meta in options %}
            {% if meta[2].includes?( " " ) %}
              opts.on( {{meta[1]}}, {{meta[2]}}, {{meta[3]}} ) { | v | @{{name}} = v }
            {% else %}
              opts.on( {{meta[1]}}, {{meta[2]}}, {{meta[3]}} ) { @{{name}} = true }
            {% end %}
          {% end %}
        end
      end

      declare_options(
        release:    { Bool,    "-r",      "--release",         "Compile in optimized Release mode",           false },
        force:      { Bool,    "-f",      "--force",           "Bypass cache and force recompilation",        false },
        run_after:  { Bool,    "-x",      "--run",             "Execute binary after successful compilation", false },
        entrypoint: { String?, "-e PATH", "--entrypoint PATH", "Specify main entrypoint file",                nil   },
        output:     { String?, "-o PATH", "--output PATH",     "Specify binary path or name",                 nil   }
      )

      #--------------------------------------------------------------------------

      def initialize ( @argv : Array(String) )
        @config      = FConfig.from_shard
        @passthrough = [] of String
      end

      def call : Int32
        strip_command!
        extract_passthrough!

        remaining = parse_options!

        apply_remaining!( remaining )
        apply_overrides!

        execute_builder
      end

      #--------------------------------------------------------------------------

      private def strip_command! : Nil
        @argv.shift if @argv.first? == "build"
      end

      private def extract_passthrough! : Nil
        if sep = @argv.index( "--" )
          @passthrough = @argv[ ( sep + 1 ).. ]
          @argv        = @argv[ ...sep ]
        end
      end

      private def parse_options! : Array(String)
        parser = OptionParser.new do |opts|
          opts.banner = "Usage: krystal [options] [-- crystal args]"

          bind_options!( opts )

          opts.on("-h", "--help", "Show help context") do
            puts opts
            exit 0
          end
        end

        argv_clone = @argv.clone
        parser.parse(argv_clone)
        argv_clone
      end

      private def apply_remaining! ( remaining : Array(String) ) : Nil
        if remaining.first? && File.file?( remaining.first )
          @entrypoint = remaining.first
        end
      end

      private def apply_overrides! : Nil
        @config.build_mode = EBuildMode::Release if @release

        if path = @output
          @config.output_dir  = File.dirname( path )
          @config.binary_name = File.basename( path )
        end

        if entrypoint = @entrypoint
          @config.entrypoint = entrypoint
        end
      end

      private def execute_builder : Int32
        FBuilder.new(
          @config,
          force:       @force,
          run_after:   @run_after,
          passthrough: @passthrough
        ).call
      end

    end

    #--------------------------------------------------------------------------

  end


end
