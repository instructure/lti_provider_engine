require 'ostruct'

require 'ims'

require "lti_provider/config"
require "lti_provider/lti_application"
require 'lti_provider/lti_config'
require 'lti_provider/lti_xml_config'
require "lti_provider/xml_config"

module LtiProvider
  mattr_accessor :app_root

  def self.setup
    yield self
  end
end

require "lti_provider/engine"

