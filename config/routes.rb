Rails.application.routes.draw do

  devise_for :users
  get "/", to: "tweets#index"

  get "tweets/fetch_tweets", to: "tweets#fetch_tweets"

  get "tweets/rejected", to: "tweets#rejected"

  get "tweets/reject", to: "tweets#mark_rejected"

  get "tweets/completed", to: "tweets#done"

  get "tweets/complete", to: "tweets#mark_done"

  get "tweets/saved", to: "tweets#favorited"

  get "tweets/save", to: "tweets#mark_favorited"

  get "tweets/blacklist_user", to: "tweets#blacklist_user"

  post "tweets", to: "tweets#create"

  post "blacklists", to: "blacklists#create"

  root to: "tweets#index"
end
