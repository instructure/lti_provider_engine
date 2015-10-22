require 'oauth/request_proxy/rack_request'

module LtiProvider
  class LtiController < LtiProvider::ApplicationController
    skip_before_filter :require_lti_launch
    after_filter :allow_iframe, only: [:launch, :cookie_test, :consume_launch]

    def launch
      app = Doorkeeper::Application.where(uid: params['oauth_consumer_key']).first if params['oauth_consumer_key'].present?
      provider = IMS::LTI::ToolProvider.new(app.uid, app.secret, params) if app
      # provider ||= IMS::LTI::ToolProvider.new(params['oauth_consumer_key'], LtiProvider::Config.secret, params)
      launch = Launch.initialize_from_request(provider, request)

      if !launch.valid_provider?
        msg = "#{launch.lti_errormsg} Please be sure you are launching this tool from the link provided in Canvas."
        return show_error msg
      elsif launch.save
        session[:cookie_test] = true
        redirect_to cookie_test_path(nonce: launch.nonce)
      else
        return show_error "Unable to launch #{LtiProvider::XmlConfig.tool_title}. Please check your External Tools configuration and try again."
      end
    end

    def cookie_test
      consume_launch
      return
      if session[:cookie_test]
        # success!!! we've got a session!
        consume_launch
      else
        render
      end
    end

    def consume_launch
      launch = Launch.where("created_at > ?", 5.minutes.ago).find_by_nonce(params[:nonce])

      if launch
        [:account_id, :course_name, :course_id, :canvas_url, :tool_consumer_instance_guid,
         :user_id, :user_name, :user_roles, :user_avatar_url].each do |attribute|
          session["lti_#{attribute}".to_sym] = launch.public_send(attribute)
        end

        resource_id = launch[:provider_params]['custom_opened_resource_id']
        launch_presentation_return_url = launch[:provider_params]['launch_presentation_return_url']

        link = "#{ENV['LTI_RUNNER_LINK'].sub(':resource_id', resource_id.to_s)}"
        if launch[:provider_params]['custom_oauth_access_token'].present?
          link += "custom_oauth_access_token=#{launch[:provider_params]['custom_oauth_access_token']}"
        else
          # get/create user, authorize user and send auth data
          # authToken=7ddadf7341cfa062d7de4f2127d452a8&userId=323304&
        end
        link += "lti_nonce=#{params[:nonce]}&launch_presentation_return_url=#{CGI.escape(launch_presentation_return_url)}"
        redirect_to link
      else
        return show_error "The tool was not launched successfully. Please try again."
      end
    end

    def configure
      respond_to do |format|
        format.xml do
          render xml: Launch.xml_config(lti_launch_url)
        end
      end
    end

    protected
      def show_error(message)
        render text: message
      end

    private
      def allow_iframe
        response.headers.except! 'X-Frame-Options'
      end

  end
end
