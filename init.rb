require 'activesupport'
require 'atom' # TODO: add ratom _dependency_

__DIR__ = File.dirname(__FILE__)
Dir.glob(File.join(__DIR__, 'lib', '**', '*.rb')) { |filename| require filename }