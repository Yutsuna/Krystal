module Krystal


  class FWatcher

    @time : Time::Instant

    #--------------------------------------------------------------------------

    def initialize
      @time = Time.instant
    end

    #--------------------------------------------------------------------------

    def elapsed : Time::Span
      Time.instant - @time
    end

    #--------------------------------------------------------------------------

    def elapsed_human : String
      span      = elapsed
      total_ms  = span.total_milliseconds

      case total_ms
      when .< 1.0
        "#{(total_ms * 1000).round(0).to_i}µs"
      when .< 1000.0
        "#{total_ms.round(1)}ms"
      when .< 60_000.0
        "#{(total_ms / 1000.0).round(2)}s"
      else
        total_s = (total_ms / 1000.0).to_i
        mm, ss  = total_s.divmod(60)
        hh, mm  = mm.divmod(60)
        hh > 0 ? "%dh%02dm%02ds" % {hh, mm, ss} : "%dm%02ds" % {mm, ss}
      end
    end

    #--------------------------------------------------------------------------

    def self.measure( &block )
      sw = FWatcher.new
      result = yield
      {result, sw}
    end

    #--------------------------------------------------------------------------

  end


end
