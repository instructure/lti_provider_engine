module LtiProvider
  class Engine < ::Rails::Engine
    isolate_namespace LtiProvider

    initializer "lti_provider.load_app_instance_data" do |app|
      LtiProvider.setup do |config|
        config.app_root = app.root
      end
    end

    initializer "lti_provider.lti_config" do |app|
      LtiProvider::LtiConfig.setup!
    end

    initializer "lti_provider.lti_xml_config" do |app|
      LtiProvider::LtiXmlConfig.setup!
    end
  end
end
