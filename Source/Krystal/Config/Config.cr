module Krystal


  enum EBuildMode
    Release     #-- production
    Fast        #-- -O3 multi-module
    Balanced    #-- -O2
    Debug       #-- development
  end


  class FConfig

    include MDumpable

    #--------------------------------------------------------------------------

    property run_before   : Array(String) = [] of String

    #--------------------------------------------------------------------------

    property src_dir      : String        = "src"
    property source_glob  : String        = "**/*.cr"
    property entrypoint   : String        = "main.cr"
    property manifests    : Array(String) = ["shard.yml", "shard.lock"]

    #--------------------------------------------------------------------------

    property output_dir   : String        = "bin"
    property binary_name  : String        = File.basename( Dir.current )

    #--------------------------------------------------------------------------

    property cache_dir    : String        = ".KrystalCache/"
    property cache_file   : String        = ".KrystalCache/Cache.json"

    #--------------------------------------------------------------------------

    property nprocs        : UInt32       = System.cpu_count.to_u32
    property hash_workers  : UInt32       = System.cpu_count.to_u32

    #--------------------------------------------------------------------------

    property crystal_bin  : String        = "crystal"
    property mold_bin     : String        = "mold"
    property build_mode   : EBuildMode    = EBuildMode::Fast
    property extra_args   : Array(String) = [] of String

    #--------------------------------------------------------------------------

    property spec_dir         : String        = Dir.exists?( "Spec" ) ? "Spec" : "spec"
    property spec_glob        : String        = "**/*.cr"
    property spec_binary_name : String        = "specs"
    property spec_cache_file  : String        = ".KrystalCache/Cache.spec.json"
    property? spec_mode       : Bool          = false

    #--------------------------------------------------------------------------

    def binary_path : String
      if @spec_mode
        File.join( output_dir, spec_binary_name )
      else
        File.join( output_dir, binary_name )
      end
    end

    #--------------------------------------------------------------------------

    def fingerprint : String
      ep = @spec_mode ? "spec_runner.cr" : entrypoint
      [ ep, build_mode.to_s, extra_args, Crystal::VERSION ].inspect
    end

    #--------------------------------------------------------------------------

  end


end
