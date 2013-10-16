require 'oauth/request_proxy/rack_request'

module LtiProvider
  class LtiController < ApplicationController
    skip_before_filter :require_lti_launch

    def launch
      provider = IMS::LTI::ToolProvider.new(params['oauth_consumer_key'], LtiProvider::Config.secret, params)
      launch = Launch.initialize_from_request(provider, request)

      if !launch.valid_provider?
        msg = "#{launch.lti_errormsg} Please be sure you are launching this tool from the link provided in Canvas."
        return show_error msg
      elsif launch.save
        session[:cookie_test] = true
        redirect_to cookie_test_path(nonce: launch.nonce)
      else
        return show_error "Unable to launch #{LtiProvider::XmlConfig.tool_name}. Please check your External Tools configuration and try again."
      end
    end

    def cookie_test
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
          session[attribute] = launch.public_send(attribute)
        end

        launch.destroy

        redirect_to main_app.root_path
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
  end
end
