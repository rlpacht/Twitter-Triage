Rails.application.routes.draw do

  # concern :paginatable do
  #   get '(page/:page)', :action => :index, :on => :collection, :as => ''
  # end

  # resources :my_resources, :concerns => :paginatable

  get "/", to: "tweets#index"

  get "tweets/fetch_tweets", to: "tweets#fetch_tweets"

  get "tweets/rejected", to: "tweets#rejected"

  get "tweets/reject", to: "tweets#mark_rejected"

  get "tweets/completed", to: "tweets#done"

  get "tweets/complete", to: "tweets#mark_done"

  get "tweets/saved", to: "tweets#favorited"

  get "tweets/save", to: "tweets#mark_favorited"
end
