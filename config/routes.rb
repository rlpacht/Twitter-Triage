Rails.application.routes.draw do
  get "/", to: "tweets#index"

  post "tweets/update", to: "tweets#update"
end
