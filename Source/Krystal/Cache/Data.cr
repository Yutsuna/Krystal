require "json"
require "digest/sha256"

module Krystal


  struct FCacheData

    include JSON::Serializable

    #--------------------------------------------------------------------------

    property sources_hash     : String
    property manifests_hash   : String
    property binary           : String
    property build_mode       : EBuildMode
    property built_at         : String
    property crystal_version  : String

    #--------------------------------------------------------------------------

    def initialize ( @sources_hash : String, @manifests_hash : String, @binary : String, @build_mode : EBuildMode, @built_at : String, @crystal_version : String )
    end

    #--------------------------------------------------------------------------

    def hash : String
      Digest::SHA256.hexdigest( sources_hash + manifests_hash )
    end

    #--------------------------------------------------------------------------

  end


end
