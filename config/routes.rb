Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
  scope "/v1" do
    resources :users
    patch "/users/:id/update_tags", to: "users#update_tags"
    post "/oauth", to: "oauth#create"
    resources :sessions, only: [:create]
    resources :posts
    resources :likes, only: [:create, :destroy]
    resources :follows, only: [:create]
    delete "/follows", to: "follows#destroy"
    get "users/:name/recent_followings", to: "follows#recent_followings"
    get "users/:name/recent_followers",  to: "follows#recent_followers"
    get "users/:id/timeline", to: "posts#timeline"
  end
end
