class ApplicationController < ActionController::Base
  include LtiProvider::LtiApplication
  
  protect_from_forgery
end
