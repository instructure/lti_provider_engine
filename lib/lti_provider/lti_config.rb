module LtiProvider
  module LTIConfig
    mattr_accessor :key, :secret, :require_canvas

    def self.load_config
      YAML::load(File.open(config_file))[Rails.env]
    end

    def self.config_file
      LtiProvider.app_root.join('config/lti.yml')
    end

    def self.setup!
      if File.exists?(config_file)
        Rails.logger.info "Initializing LTI key and secret using configuration in #{config_file}"
        config = load_config
        self.key = config['key']
        self.secret = config['secret']
        self.require_canvas = config['require_canvas']
      elsif ENV['LTI_KEY'].present? && ENV['LTI_SECRET'].present?
        Rails.logger.info "Initializing LTI key and secret using environment vars LTI_KEY and LTI_SECRET"
        self.key = ENV['LTI_KEY']
        self.secret = ENV['LTI_SECRET']
        self.require_canvas = !!ENV['LTI_REQUIRE_CANVAS']
      else
        raise "Warning: LTI key and secret not configured for #{Rails.env})."
      end
    end
  end
end
