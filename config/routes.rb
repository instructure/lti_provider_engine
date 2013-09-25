LtiProvider::Engine.routes.draw do
  match "/cookie_test", to: "lti#cookie_test", as: "cookie_test"
  match "/consume_launch", to: "lti#consume_launch", as: "consume_launch"
  match "/launch", to: "lti#launch", as: "lti_launch"
  match "/configure(.:format)", to: "lti#configure", as: "lti_configure"
end
