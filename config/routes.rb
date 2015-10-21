LtiProvider::Engine.routes.draw do
  get "/lti/cookie_test", to: "lti#cookie_test", as: "cookie_test"
  get "/lti/consume_launch", to: "lti#consume_launch", as: "consume_launch"
  post "/lti/launch", to: "lti#launch", as: "lti_launch"
  get "/lti/configure(.:format)", to: "lti#configure", as: "lti_configure"
end
