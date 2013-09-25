$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "lti_provider/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "lti_provider"
  s.version     = LtiProvider::VERSION
  s.authors     = ["Dave Donahue", "Adam Anderson"]
  s.email       = ["adam.anderson@12spokes.com"]
  s.homepage    = ""
  s.summary     = ""
  s.description = ""

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.12"
  s.add_dependency 'httparty', '>= 0.9.0'
  s.add_dependency 'ims-lti', '1.0.2'
  s.add_dependency 'nokogiri', '~> 1.5.5'
  s.add_dependency 'redis', '>= 2.2.2'

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec"
  s.add_development_dependency "shoulda-matchers"
  s.add_development_dependency "webmock"
end
