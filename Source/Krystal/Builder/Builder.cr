require "file_utils"

module Krystal


  class FBuilder

    @config       : FConfig
    @force        : Bool
    @run_after    : Bool
    @passthrough  : Array(String)
    @cache        : FCacheStore
    @scanner      : FSourceScanner

    #--------------------------------------------------------------------------

    def initialize ( @config : FConfig, @force : Bool = false, @run_after : Bool = false, @passthrough : Array(String) = [] of String )
      @cache   = FCacheStore.new( @config.cache_file )
      @scanner = FSourceScanner.new( @config )
    end

    #--------------------------------------------------------------------------

    def call : Int32
      total = FWatcher.new
      FLog.log "Krystal Builder — #{@config.nprocs} cores detected"

      digest = compute_digest
      return 1 if digest.nil?

      if cache_hit?( digest )
        return finish_cached( total )
      end

      status = compile
      if status.success?
        persist_cache( digest )
        FLog.ok "Build completed in #{total.elapsed_human} -> #{@config.binary_path}"
        return run_binary if @run_after
        0
      else
        FLog.error "Build failed (exit #{status.exit_code}) after #{total.elapsed_human}"
        status.exit_code
      end
    end

    #--------------------------------------------------------------------------

    private def compute_digest : String?
      FLog.step "Scanning sources (#{@config.src_dir}/#{@config.source_glob})..."
      files, scan_sw = FWatcher.measure { @scanner.files }

      if files.empty?
        FLog.error "No source files found in #{@config.src_dir.inspect}."
        return nil
      end

      digest, hash_sw = FWatcher.measure { @scanner.digest( files ) }
      workers_used = { @config.hash_workers, files.size }.min

      FLog.info "  #{files.size} files scanned in #{scan_sw.elapsed_human} " \
                "SHA256 hash in #{hash_sw.elapsed_human} " \
                "(#{workers_used} workers)"
      FLog.info "  global hash: #{digest[ 0, 16 ]}..."
      digest
    end

    #--------------------------------------------------------------------------

    private def cache_hit? ( digest : String ) : Bool
      return false if @force

      if cached = @cache.read
        cached.hash == digest && File::Info.executable?( @config.binary_path )
      else
        false
      end
    end

    #--------------------------------------------------------------------------

    private def finish_cached ( total : FWatcher ) : Int32
      FLog.ok "Cache: No sources changed, binary reused " \
              "(#{@config.binary_path}) in #{total.elapsed_human} ⚡"
      return run_binary if @run_after
      0
    end

    #--------------------------------------------------------------------------

    private def persist_cache ( digest : String ) : Nil
      data = FCacheData.new(
        hash:             digest,
        binary:           @config.binary_path,
        build_mode:       @config.build_mode,
        built_at:         Time.utc.to_rfc3339,
        crystal_version:  Crystal::VERSION
      )
      @cache.write( data )
    end

    #--------------------------------------------------------------------------

    private def compile : FBuildStatus
      unless FToolchain.which( @config.crystal_bin )
        FLog.error "Compiler not found: #{@config.crystal_bin.inspect}"
        return FBuildStatus.new( false, 127 )
      end

      Dir.mkdir_p( @config.output_dir )
      Dir.mkdir_p( @config.cache_dir )

      cmd = build_command
      env = build_env

      FLog.step "Compiling: #{cmd.join( " " )}"
      FLog.info "  CRYSTAL_CACHE_DIR=#{env[ "CRYSTAL_CACHE_DIR" ]} (reusing .o files)"

      status, compile_sw = FWatcher.measure { stream_subprocess( env, cmd ) }

      if status.success?
        FLog.ok "Compilation + linking phase: #{compile_sw.elapsed_human}"
      else
        FLog.error "Compilation failed: #{compile_sw.elapsed_human}"
      end
      status
    end

    #--------------------------------------------------------------------------

    private def build_command : Array(String)
      cmd = [
        @config.crystal_bin, "build", @config.entrypoint,
        "-o", @config.binary_path,
        "--threads", @config.nprocs.to_s,
        "--progress", "--stats",
      ]
      cmd << "--release" if @config.build_mode == EBuildMode::Release
      cmd.concat( linker_flags )
      cmd.concat( @config.extra_args )
      cmd.concat( @passthrough )
      cmd
    end

    #--------------------------------------------------------------------------

    private def linker_flags : Array(String)
      mold = FToolchain.which( @config.mold_bin )
      if mold
        FLog.step "Linker: mold detected (#{mold}) — multi-threaded linking x#{@config.nprocs}"
        [ "--link-flags", "-fuse-ld=mold -Wl,--thread-count=#{@config.nprocs}" ]
      else
        FLog.warn "mold not found — falling back to the system linker (ld). " \
                  "Install mold to speed up linking."
        [] of String
      end
    end

    #--------------------------------------------------------------------------

    private def build_env : Hash(String, String)
      { "CRYSTAL_CACHE_DIR" => @config.cache_dir }
    end

    #--------------------------------------------------------------------------

    private def stream_subprocess ( env : Hash(String, String), cmd : Array(String) ) : FBuildStatus
      program = cmd[ 0 ]
      args    = cmd[ 1.. ]

      stdout_reader, stdout_writer = IO.pipe
      stderr_reader, stderr_writer = IO.pipe

      process = Process.new(
        program,
        args,
        env:    env,
        input:  Process::Redirect::Close,
        output: stdout_writer,
        error:  stderr_writer
      )

      stdout_writer.close
      stderr_writer.close

      stderr_buffer = IO::Memory.new
      stdout_done   = Channel(Nil).new
      stderr_done   = Channel(Nil).new

      stdout_fiber = spawn do
        stdout_reader.each_line { |line| FLog.command "  #{line}" }
        stdout_done.send(nil)
      end

      stderr_fiber = spawn do
        stderr_reader.each_line { |line| stderr_buffer.puts line }
        stderr_done.send(nil)
      end

      status = process.wait

      stdout_done.receive
      stderr_done.receive

      puts ""

      unless status.success?
        report_compiler_errors( stderr_buffer.to_s )
      end

      FBuildStatus.new( status.success?, status.exit_code )
    rescue exception
      FLog.error "Cannot launch the compiler: #{exception.message}"
      FBuildStatus.new( false, 127 )
    end

    #--------------------------------------------------------------------------

    private def report_compiler_errors ( buffer : String ) : Nil
      FLog.error "Crystal compiler output:"
      buffer.each_line do | line |
        STDERR.puts "  #{EAnsiColor::RED}│#{EAnsiColor::RESET} #{line}"
      end
      STDERR.flush
    end

    #--------------------------------------------------------------------------

    private def run_binary : Int32
      FLog.step "Running #{@config.binary_path}…"
      status = Process.run( @config.binary_path, shell: true, output: Process::Redirect::Inherit, error: Process::Redirect::Inherit )
      status.exit_code
    end

    #--------------------------------------------------------------------------

  end


end
