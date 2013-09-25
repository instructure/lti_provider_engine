require 'uri'

module LtiProvider
  class Launch < ActiveRecord::Base
    validates :canvas_url, :provider_params, :nonce, presence: true

    attr_accessor :lti_errormsg

    serialize :provider_params

    def self.initialize_from_request(provider, request)
      launch = new

      launch.validate_provider(provider, request)

      launch.provider_params = provider.to_params
      launch.canvas_url      = launch.api_endpoint(provider)
      launch.nonce           = launch.provider_params['oauth_nonce']

      launch
    end

    def self.xml_config(lti_launch_url)
      account_navigation = {
        url: lti_launch_url,
        text: LtiProvider::Config.tool_name,
        visibility: "admins"
      }
      course_navigation = {
        url: lti_launch_url,
        text: LtiProvider::Config.tool_name,
        visibility: "admins"
      }
      user_navigation = nil

      tc = IMS::LTI::ToolConfig.new(launch_url: lti_launch_url,
                                    title: LtiProvider::Config.tool_title,
                                    description: LtiProvider::Config.tool_description)

      tc.set_ext_params LtiProvider::Config.source_domain,
        privacy_level: LtiProvider::Config.privacy_level,
        tool_id: LtiProvider::Config.tool_id
      tc.set_ext_param LtiProvider::Config.source_domain, :course_navigation, course_navigation if course_navigation
      tc.set_ext_param LtiProvider::Config.source_domain, :account_navigation, account_navigation if account_navigation
      tc.set_ext_param LtiProvider::Config.source_domain, :user_navigation, user_navigation if user_navigation

      tc.to_xml(:indent => 2)
    end

    {
      'context_label'                  => :course_name,
      'custom_canvas_account_id'       => :account_id,
      'custom_canvas_course_id'        => :course_id,
      'custom_canvas_user_id'          => :user_id,
      'lis_person_name_full'           => :user_name,
      'roles'                          => :user_roles,
      'tool_consumer_instance_guid'    => :tool_consumer_instance_guid,
      'user_image'                     => :user_avatar_url
    }.each do |provider_param, method_name|
      define_method(method_name) { provider_params[provider_param] }
    end

    def valid_provider?
      !!@valid_provider
    end

    def validate_provider(provider, request)
      self.lti_errormsg =
        if provider.consumer_key.blank?
          "Consumer key not provided."
        elsif provider.consumer_secret.blank?
          "Consumer secret not configured on provider."
        elsif !provider.valid_request?(request)
          "The OAuth signature was invalid."
        elsif oauth_timestamp_too_old?(provider.request_oauth_timestamp)
          "Your request is too old."
        end

      @valid_provider = self.lti_errormsg.blank?
    end

    def api_endpoint(provider)
      if provider.launch_presentation_return_url
        uri = URI.parse(provider.launch_presentation_return_url)
        domain = "#{uri.scheme}://#{uri.host}"
        domain += ":#{uri.port}" unless uri.port.nil? || [80, 443].include?(uri.port.to_i)
        return domain
      end
    end

    private
    def oauth_timestamp_too_old?(timestamp)
      Time.now.utc.to_i - timestamp.to_i > 1.hour.to_i
    end
  end
end
