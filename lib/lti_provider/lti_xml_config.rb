module LtiProvider
  module LtiXmlConfig
    def self.load_config
      YAML::load(File.open(config_file))[Rails.env]
    end

    def self.config_file
      LtiProvider.app_root.join('config/lti_xml.yml')
    end

    def self.setup!
      config = LtiProvider::XmlConfig
      if File.exists?(config_file)
        Rails.logger.info "Initializing LTI XML config using configuration in #{config_file}"
        load_config.each do |k,v|
          config.send("#{k}=", v)
        end
      else
        raise "Warning: LTI XML config not configured for #{Rails.env})."
      end
    end
  end
end
