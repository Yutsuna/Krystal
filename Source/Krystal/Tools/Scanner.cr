require "digest/sha256"

module Krystal


  class FSourceScanner

    @config : FConfig

    #--------------------------------------------------------------------------

    def initialize ( @config : FConfig )
    end

    #--------------------------------------------------------------------------

    def files : Array(String)
      sources   = Dir.glob( File.join( @config.src_dir, @config.source_glob ) ).select { | path | File.file?( path ) }
      manifests = @config.manifests.select { | path | File.file?( path ) }
      ( sources + manifests ).sort
    end

    #--------------------------------------------------------------------------

    def digest(file_list : Array(String)) : String
      workers_count = { @config.hash_workers, file_list.size }.min.clamp(1, 64)

      task_chan   = Channel({Int32, String}).new( file_list.size )
      result_chan = Channel({Int32, String}).new( file_list.size )

      workers_count.times do
        spawn do
          loop do
            task = task_chan.receive?
            break unless task
            idx, path = task

            begin
              info = File.info path
              hasher = Digest::SHA256.new
              hasher.update("#{path}|#{info.size}|#{info.modification_time.to_unix_ms}|")

              buffer = Bytes.new(8192)
              File.open( path ) do | file |
                while ( read_bytes = file.read( buffer ) ) > 0
                  hasher.update( buffer[0, read_bytes] )
                end
              end
              result_chan.send( {idx, hasher.hexfinal} )
            rescue exception
              result_chan.send( {idx, "ERROR:#{exception.message}"} )
            end
          end
        end
      end

      file_list.each_with_index { |path, idx| task_chan.send({idx, path}) }
      task_chan.close

      results = Array(String).new( file_list.size, "" )
      file_list.size.times do
        idx, file_hash = result_chan.receive
        results[idx] = file_hash
      end

      reducer = Digest::SHA256.new
      reducer.update( @config.fingerprint )
      results.each { |h| reducer.update(h) }
      reducer.hexfinal
    end

    #--------------------------------------------------------------------------

  end


end
