module LtiProvider
  module LtiConfig
    def self.load_config
      YAML::load(File.open(config_file))[Rails.env]
    end

    def self.config_file
      LtiProvider.app_root.join('config/lti.yml')
    end

    def self.setup!
      config = LtiProvider::Config
      if File.exists?(config_file)
        Rails.logger.info "Initializing LTI key and secret using configuration in #{config_file}"
        load_config.each do |k,v|
          config.send("#{k}=", v)
        end
      elsif ENV['LTI_KEY'].present? && ENV['LTI_SECRET'].present?
        Rails.logger.info "Initializing LTI key and secret using environment vars LTI_KEY and LTI_SECRET"
        config.key = ENV['LTI_KEY']
        config.secret = ENV['LTI_SECRET']
        config.require_canvas = !!ENV['LTI_REQUIRE_CANVAS']
      else
        raise "Warning: LTI key and secret not configured for #{Rails.env})."
      end
    end
  end
end
