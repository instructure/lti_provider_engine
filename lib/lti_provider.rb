require 'ostruct'

require 'ims'

require "lti_provider/config"
require "lti_provider/lti_application"
require 'lti_provider/lti_config'

module LtiProvider
  mattr_accessor :app_root

  def self.setup
    yield self
  end

  def self.config
    yield(LtiProvider::Config)
  end
end

require "lti_provider/engine"

