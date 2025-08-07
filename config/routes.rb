Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
  scope :v1 do
    get "users/:name", to: "users#show_by_name"
    resources :users
    resources :user_social_profiles, only: [ :create, :update, :destroy ]
    resources :sessions,             only: [ :create ]
    resources :oauth,                only: [ :create ]
    resources :posts
    resources :likes,                only: [ :create, :destroy ]
    resources :messages, only: [ :index, :create ] do
      member do
        patch :read # /v1/messages/:id/read
      end
    end
    resources :follows, only: [ :create, :destroy ]
    get "users/:id/followers", to: "follows#followers"
    get "users/:id/following", to: "follows#following"
    get "timeline", to: "timeline#index"
  end
end
