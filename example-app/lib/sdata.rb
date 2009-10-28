SData = Module.new

__DIR__ = File.dirname(__FILE__)
require File.join(__DIR__, 'sdata', 'predicate.rb')
require File.join(__DIR__, 'sdata', 'conditions_builder.rb')
require File.join(__DIR__, 'sdata', 'controller_mixin.rb')
require File.join(__DIR__, 'sdata', 'active_record_extensions.rb')
require File.join(__DIR__, 'sdata', 'router_mixin.rb')