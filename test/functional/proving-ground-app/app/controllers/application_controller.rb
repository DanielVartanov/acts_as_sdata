# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  rescue_from Exception, :with => :global_rescue
  sdata_rescue_support
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  
  def global_rescue(exception)
    sdata_global_rescue(exception, request.env['REQUEST_URI'])
  end
end
