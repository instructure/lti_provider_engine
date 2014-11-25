module LtiProvider
  module LtiApplication
    extend ActiveSupport::Concern

    module ClassMethods
    end

    included do
      before_filter :require_lti_launch
    end

    protected
    def require_lti_launch
      if canvas_url.blank? || user_id.blank?
        reset_session
        prompt_for_launch
      end
    end

    def prompt_for_launch
      render text: 'Please launch this tool from Canvas and then try again.'
    end

    def canvas_url
      session[:canvas_url]
    end

    def user_id
      session[:user_id]
    end

    def current_course_id
      session[:course_id]
    end

    def tool_consumer_instance_guid
      session[:tool_consumer_instance_guid]
    end

    def course_launch?
      current_course_id.present?
    end

    def current_account_id
      session[:account_id]
    end

    def account_launch?
      current_account_id.present?
    end

    def user_roles
      session[:user_roles]
    end

    def not_acceptable
      render text: "Unable to process request", status: 406
    end
  end
end
