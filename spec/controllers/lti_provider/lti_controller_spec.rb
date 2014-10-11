require 'spec_helper'

describe LtiProvider::LtiController do
  let(:user_id) { "1" }
  let(:parameters) {
    {
      'launch_url' => "http://#{request.host}",
      'custom_canvas_user_id' => user_id,
      'launch_presentation_return_url' => "http://test.canvas",

      'lti_version' => 'LTI-1p0',
      'lti_message_type' => 'basic-lti-launch-request',
      'action' => 'launch',
      'controller' => 'lti_provider/lti'
    }
  }

  def create_consumer(key, secret)
    consumer = IMS::LTI::ToolConsumer.new(key, secret, parameters)
    consumer.resource_link_id = 'abc'
    consumer
  end

  def post_lti_request!(key, secret)
    consumer = create_consumer(key, secret)

    # the oauth rack request proxy doesn't know to strip the 'action' and
    # 'controller' parameters, so we need to stub them here so the request also
    # gets signed with them
    allow(consumer).to receive(:to_params).and_return(parameters)

    data = consumer.generate_launch_data
    request.env['RAW_POST_DATA'] = data.to_query
    request.env['CONTENT_TYPE'] = 'application/x-www-form-urlencoded'
    request.env['HTTP_REFERER'] = 'http://test.canvas/external_tools/1'

    post :launch, data.merge(use_route: :lti_provider)
  end

  describe "GET cookie_test" do
    context "when successful" do
      it "proceeds to oauth" do
        controller.session[:cookie_test] = true
        expect(controller).to receive(:consume_launch)
        get :cookie_test, use_route: :lti_provider
      end
    end

    context "when failed" do
      it "renders a message" do
        get :cookie_test, use_route: :lti_provider
        expect(response).to render_template('cookie_test')
      end
    end
  end

  describe "POST launch" do
    context "with a valid key" do
      before do
        post_lti_request!(LtiProvider::Config.key, LtiProvider::Config.secret)
      end

      it "performs a cookie test and passes along the nonce" do
        expect(response.redirect_url).to include(lti_provider.cookie_test_url(nonce: '', host: request.host))
      end

      it "saves the launch record" do
        expect(LtiProvider::Launch.first.user_id).to eq user_id
      end
    end

    context "without a key" do
      it "renders an error message" do
        post_lti_request!('', '')
        expect(response.body).to match "Consumer key not provided."
      end
    end

    context "with an invalid secret" do
      it "renders an error message" do
        post_lti_request!(LtiProvider::Config.key, 'invalid')
        expect(response.body).to match "The OAuth signature was invalid."
      end
    end
  end

  describe "consume_launch" do
    let!(:launch) do
      LtiProvider::Launch.create!({
        canvas_url: 'http://canvas',
        nonce:  'abcd',
        provider_params: {
          'custom_canvas_course_id' => 1,
          'custom_canvas_user_id' => 2,
          'tool_consumer_instance_guid' => '123abc'
        }
      })
    end

    describe "a successful launch" do
      it "sets the session params" do
        get :consume_launch, nonce: 'abcd', use_route: :lti_provider
        expect(session[:course_id]).to eq 1
        expect(session[:user_id]).to eq 2
        expect(session[:canvas_url]).to eq 'http://canvas'
        expect(session[:tool_consumer_instance_guid]).to eq '123abc'
      end

      it "destroys the launch" do
        get :consume_launch, nonce: 'abcd', use_route: :lti_provider
        expect(LtiProvider::Launch.count).to eq 0
      end
    end

    describe "an expired nonce" do
      before do
        launch.update_attribute(:created_at, 10.minutes.ago)
      end

      it "shows an error" do
        get :consume_launch, nonce: 'abcd', use_route: :lti_provider
        expect(response.body).to be =~ /not launched successfully/
      end
    end

    describe "a failed launch" do
      it "shows an error" do
        get :consume_launch, nonce: 'invalid', use_route: :lti_provider
        expect(response.body).to be =~ /not launched successfully/
      end
    end
  end

  describe "configure.xml" do
    it "succeeds" do
      get :configure, format: :xml, use_route: :lti_provider
      expect(response).to be_success
    end
  end
end
