require 'spec_helper'

describe LtiProvider::Launch do
  describe "validations" do
    subject(:launch) do
      l = LtiProvider::Launch.new
      l.provider_params = {}
      l
    end

    it { should validate_presence_of :canvas_url }
    it { should validate_presence_of :nonce }
    it { should validate_presence_of :provider_params }
  end

  describe ".initialize_from_request" do
    let(:provider) do
      p = double('provider')
      p.stub(
        to_params: {
          'custom_canvas_course_id' => 1,
          'custom_canvas_user_id' => 2,
          'oauth_nonce' => 'nonce',
          'tool_consumer_instance_guid' => "123abc",
        },
        launch_presentation_return_url: "http://example.com",
        consumer_key: "key",
        consumer_secret: "secret",
        valid_request?: true,
        request_oauth_timestamp: Time.now
      )
      p
    end

    let(:request) do
      r = double('request')
      r.stub(env: {'HTTP_REFERER' => "http://example.com"})
      r
    end

    subject(:launch) { LtiProvider::Launch.initialize_from_request(provider, request) }

    its(:course_id) { should == 1 }
    its(:tool_consumer_instance_guid) { should == '123abc' }
    its(:user_id) { should == 2 }
    its(:nonce) { should == 'nonce' }
    its(:account_id) { should be_nil }
    its(:canvas_url) { should == 'http://example.com' }
  end

  describe "xml_config" do
    let(:lti_launch_url) { "http://example.com/launch" }
    let(:doc) { Nokogiri::XML(xml) }

    subject(:xml) { LtiProvider::Launch.xml_config(lti_launch_url) }

    it { should match(/\<\?xml/) }

    it "includes the launch URL" do
      doc.xpath('//blti:launch_url').text.should match lti_launch_url
    end

    it "includes the course_navigation option and url + text properties" do
      nav = doc.xpath('//lticm:options[@name="course_navigation"]')
      nav.xpath('lticm:property[@name="url"]').text.should == 'http://override.example.com/launch'
      nav.xpath('lticm:property[@name="text"]').text.should == "Dummy"
      nav.xpath('lticm:property[@name="visibility"]').text.should == "admins"
    end

    it "includes account_navigation" do
      nav = doc.xpath('//lticm:options[@name="account_navigation"]')
      nav.should be_present
    end

    it "includes no user_navigation" do
      nav = doc.xpath('//lticm:options[@name="user_navigation"]')
      nav.should be_empty
    end
  end
end
