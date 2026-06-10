module Krystal


  module CLI

    #--------------------------------------------------------------------------

    def self.call ( argv : Array(String) ) : Int32
      Runner.new( argv ).call
    end

    #--------------------------------------------------------------------------

  end


end
