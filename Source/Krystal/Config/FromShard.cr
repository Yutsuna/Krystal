require "yaml"
require "./Config"

module Krystal


  class FConfig

    #--------------------------------------------------------------------------

    def self.from_shard ( path : String = "shard.yml" ) : self
      config = FConfig.new

      if File.file? path
        begin
          yaml = YAML.parse( File.read path )
          config.detect_targets( yaml )

          if krystal = yaml[ "krystal" ]?
            config.parse_yaml( krystal )
          end
        rescue exception
          STDERR.puts "Error loading shard.yml: #{exception.message}"
        end
      end

      config
    end

    #--------------------------------------------------------------------------

    protected def detect_targets(yaml : YAML::Any) : Nil
      if targets = yaml["targets"]?.try(&.as_h?)
        if first_target_name = targets.keys.first?.try(&.as_s?)
          @binary_name = first_target_name
          if target = targets[first_target_name]?
            if main_file = target["main"]?.try(&.as_s?)
              @entrypoint = main_file
              @src_dir = File.dirname(main_file)
            end
          end
        end
      end
    end

    protected def parse_yaml ( node : YAML::Any ) : Nil
      {% for ivar in @type.instance_vars %}
        if val = node[{{ivar.name.stringify}}]?
          {% if ivar.type == String %}
            @{{ivar.name}} = val.as_s? || @{{ivar.name}}
          {% elsif ivar.type == UInt32 %}
            @{{ivar.name}} = val.as_i?.try(&.to_u32) || @{{ivar.name}}
          {% elsif ivar.type == Array(String) %}
            @{{ivar.name}} = val.as_a?.try(&.compact_map(&.as_s?)) || @{{ivar.name}}
          {% elsif ivar.type == EBuildMode %}
            if str = val.as_s?
              @{{ivar.name}} = EBuildMode.parse?(str) || @{{ivar.name}}
            end
          {% end %}
        end
      {% end %}
    end

    #--------------------------------------------------------------------------

  end


end
