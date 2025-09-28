Rails.application.routes.draw do
  devise_for :users, skip: [ :sessions, :registrations, :passwords, :confirmations, :unlocks ], controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"
  }
  devise_scope :user do
    delete "/users/sign_out", to: "devise/sessions#destroy"
  end

  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  namespace :dashboard do
    resources :profile, only: [ :index ]

    resources :tags do
      collection do
        get :search
        get :by_name
      end
    end
  end

  get "/dashboard", to: "dashboard#index"

  # Defines the root path route ("/")
  root "home#index"
end
