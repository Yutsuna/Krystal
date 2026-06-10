require "json"

module Krystal


  class FCacheStore

    getter path : String

    #--------------------------------------------------------------------------

    def initialize ( @path : String )
    end

    def read : FCacheData?
      return nil unless File.file? @path
      FCacheData.from_json( File.read @path )
    rescue exception
      FLog.warn "Corrupted cache file at #{@path}, regenerating."
      nil
    end

    def write ( data : FCacheData ) : Nil
      tmp = "#{@path}.tmp.#{Process.pid}"
      File.write( tmp, data.to_json )
      File.rename( tmp, @path )
    end

    #--------------------------------------------------------------------------

  end


end
