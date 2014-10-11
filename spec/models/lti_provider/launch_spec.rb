require 'spec_helper'

describe LtiProvider::Launch do
  describe "validations" do
    subject(:launch) do
      l = LtiProvider::Launch.new
      l.provider_params = {}
      l
    end

    it { is_expected.to validate_presence_of :canvas_url }
    it { is_expected.to validate_presence_of :nonce }
    it { is_expected.to validate_presence_of :provider_params }
  end

  describe ".initialize_from_request" do
    let(:provider) do
      p = double('provider')
      allow(p).to receive_messages(
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
      allow(r).to receive_messages(env: {'HTTP_REFERER' => "http://example.com"})
      r
    end

    subject(:launch) { LtiProvider::Launch.initialize_from_request(provider, request) }

    its(:course_id) { is_expected.to eq 1 }
    its(:tool_consumer_instance_guid) { is_expected.to eq '123abc' }
    its(:user_id) { is_expected.to eq 2 }
    its(:nonce) { is_expected.to eq 'nonce' }
    its(:account_id) { is_expected.to be_nil }
    its(:canvas_url) { is_expected.to eq 'http://example.com' }
  end

  describe "xml_config" do
    let(:lti_launch_url) { "http://example.com/launch" }
    let(:doc) { Nokogiri::XML(xml) }

    subject(:xml) { LtiProvider::Launch.xml_config(lti_launch_url) }

    it { is_expected.to match(/\<\?xml/) }

    it "includes the launch URL" do
      expect(doc.xpath('//blti:launch_url').text).to match lti_launch_url
    end

    it "includes the course_navigation option and url + text properties" do
      nav = doc.xpath('//lticm:options[@name="course_navigation"]')
      expect(nav.xpath('lticm:property[@name="url"]').text).to eq 'http://override.example.com/launch'
      expect(nav.xpath('lticm:property[@name="text"]').text).to eq "Dummy"
      expect(nav.xpath('lticm:property[@name="visibility"]').text).to eq "admins"
    end

    it "includes account_navigation" do
      nav = doc.xpath('//lticm:options[@name="account_navigation"]')
      expect(nav).to be_present
    end

    it "includes no user_navigation" do
      nav = doc.xpath('//lticm:options[@name="user_navigation"]')
      expect(nav).to be_empty
    end
  end
end
