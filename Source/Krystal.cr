require "./Krystal/Tools/**"
require "./Krystal/Config/**"
require "./Krystal/CLI/**"
require "./Krystal/Cache/**"
require "./Krystal/Builder/**"

exit( Krystal::CLI.call( ARGV ) )
