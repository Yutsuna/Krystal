require "./Krystal/Tools/**"
require "./Krystal/Config/**"
require "./Krystal/CLI/**"

exit( Krystal::CLI.call( ARGV ) )
