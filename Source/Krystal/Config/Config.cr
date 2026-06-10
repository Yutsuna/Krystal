module Krystal


  enum EBuildMode
    Release
    Debug
  end


  class FConfig

    include MDumpable

    #--------------------------------------------------------------------------

    @src_dir      : String        = "src"
    @source_glob  : String        = "**/*.cr"
    @entrypoint   : String        = "main.cr"
    @manifests    : Array(String) = ["shard.yml", "shard.lock"]

    #--------------------------------------------------------------------------

    @output_dir   : String        = "bin"
    @binary_name  : String        = File.basename( Dir.current )

    #--------------------------------------------------------------------------

    @cache_dir    : String        = ".KrystalCache/"
    @cache_file   : String        = ".KrystalCache/Cache.json"

    #--------------------------------------------------------------------------

    @nprocs        : UInt32       = System.cpu_count.to_u32
    @hash_workers  : UInt32       = System.cpu_count.to_u32

    #--------------------------------------------------------------------------

    @crystal_bin  : String        = "crystal"
    @mold_bin     : String        = "mold"
    @build_mode   : EBuildMode    = EBuildMode::Release
    @extra_args   : Array(String) = [] of String

    #--------------------------------------------------------------------------

  end


end
