module Krystal


  struct FBuildStatus

    getter? success : Bool
    getter exit_code : Int32

    #--------------------------------------------------------------------------

    def initialize ( @success : Bool, @exit_code : Int32 )
    end

    #--------------------------------------------------------------------------

  end


end
