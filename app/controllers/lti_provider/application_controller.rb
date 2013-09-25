module LtiProvider
  class ApplicationController < ActionController::Base
    include LtiProvider::LtiApplication
  end
end
