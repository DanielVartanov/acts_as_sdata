SData = Module.new

__DIR__ = File.dirname(__FILE__)
Dir.glob(File.join(__DIR__, 'sdata', '**', '*.rb')) { |filename| require filename }
