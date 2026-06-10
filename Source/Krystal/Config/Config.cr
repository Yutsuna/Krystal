module Krystal


  enum EBuildMode
    Release
    Debug
  end


  class FConfig

    include MDumpable

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
    property build_mode   : EBuildMode    = EBuildMode::Release
    property extra_args   : Array(String) = [] of String

    #--------------------------------------------------------------------------

    def binary_path : String
          File.join( output_dir, binary_name )
    end

    #--------------------------------------------------------------------------

    def fingerprint : String
      [ entrypoint, build_mode.to_s, extra_args, Crystal::VERSION ].inspect
    end

    #--------------------------------------------------------------------------

  end


end
