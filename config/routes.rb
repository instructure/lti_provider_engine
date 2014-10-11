LtiProvider::Engine.routes.draw do
  get "/cookie_test", to: "lti#cookie_test", as: "cookie_test"
  get "/consume_launch", to: "lti#consume_launch", as: "consume_launch"
  post "/launch", to: "lti#launch", as: "lti_launch"
  get "/configure(.:format)", to: "lti#configure", as: "lti_configure"
end
