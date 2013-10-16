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
    consumer.stubs(:to_params).returns(parameters)

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
        controller.should_receive(:consume_launch)
        get :cookie_test, use_route: :lti_provider
      end
    end

    context "when failed" do
      it "renders a message" do
        get :cookie_test, use_route: :lti_provider
        response.should render_template('cookie_test')
      end
    end
  end

  describe "POST launch" do
    context "with a valid key" do
      before do
        post_lti_request!(LtiProvider::Config.key, LtiProvider::Config.secret)
      end

      it "performs a cookie test and passes along the nonce" do
        response.redirect_url.should include(lti_provider.cookie_test_url(nonce: '', host: request.host))
      end

      it "saves the launch record" do
        LtiProvider::Launch.first.user_id.should == user_id
      end
    end

    context "without a key" do
      it "renders an error message" do
        post_lti_request!('', '')
        response.body.should match "Consumer key not provided."
      end
    end

    context "with an invalid secret" do
      it "renders an error message" do
        post_lti_request!(LtiProvider::Config.key, 'invalid')
        response.body.should match "The OAuth signature was invalid."
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
      },
      without_protection: true)
    end

    describe "a successful launch" do
      it "sets the session params" do
        get :consume_launch, nonce: 'abcd', use_route: :lti_provider
        session[:course_id].should == 1
        session[:user_id].should == 2
        session[:canvas_url].should == 'http://canvas'
        session[:tool_consumer_instance_guid].should == '123abc'
      end

      it "destroys the launch" do
        get :consume_launch, nonce: 'abcd', use_route: :lti_provider
        LtiProvider::Launch.count.should == 0
      end
    end

    describe "an expired nonce" do
      before do
        launch.update_attribute(:created_at, 10.minutes.ago)
      end

      it "shows an error" do
        get :consume_launch, nonce: 'abcd', use_route: :lti_provider
        response.body.should =~ /not launched successfully/
      end
    end

    describe "a failed launch" do
      it "shows an error" do
        get :consume_launch, nonce: 'invalid', use_route: :lti_provider
        response.body.should =~ /not launched successfully/
      end
    end
  end

  describe "configure.xml" do
    it "should succeed" do
      get :configure, format: :xml, use_route: :lti_provider
      response.should be_success
    end
  end
end
