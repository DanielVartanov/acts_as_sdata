require 'activesupport'
require 'atom' # TODO: add ratom dependency

__DIR__ = File.dirname(__FILE__)
Dir.glob(File.join(__DIR__, 'lib', '**', '*.rb')) { |filename| require filename }