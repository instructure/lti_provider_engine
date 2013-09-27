Rails.application.routes.draw do
  root to: "welcome#index"
  mount LtiProvider::Engine => "/"
end
