require "json"

module Krystal


  struct FCacheData

    include JSON::Serializable

    #--------------------------------------------------------------------------

    property hash             : String
    property binary           : String
    property build_mode       : EBuildMode
    property built_at         : String
    property crystal_version  : String

    #--------------------------------------------------------------------------

    def initialize ( @hash : String, @binary : String, @build_mode : EBuildMode, @built_at : String, @crystal_version : String )
    end

    #--------------------------------------------------------------------------

  end


end
