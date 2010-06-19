module SData
  module ControllerMixin
    def acts_as_sdata(options)
      cattr_accessor :sdata_options
      self.sdata_options = options
      include Actions
    end
  end
end

ActionController::Base.extend SData::ControllerMixin