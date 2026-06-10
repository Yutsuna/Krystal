module Krystal


  module FToolchain

    extend self

    #--------------------------------------------------------------------------

    def which ( bin : String ) : String?
      Process.find_executable( bin )
    end

    #--------------------------------------------------------------------------

  end


end
