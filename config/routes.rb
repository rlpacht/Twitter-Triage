Rails.application.routes.draw do
  get "/", to: "tweets#index"

  get "tweets/rejected", to: "tweets#rejected"

  post "tweets/reject", to: "tweets#mark_rejected"

  get "tweets/completed", to: "tweets#done"

  post "tweets/complete", to: "tweets#mark_done"

  get "tweets/saved", to: "tweets#favorited"

  post "tweets/save", to: "tweets#mark_favorited"
end
