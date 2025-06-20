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
    resources :sessions, only: [ :create ]
    resources :oauth,    only: [ :create ]
    resources :posts
  end
end
