Rails.application.routes.draw do
  devise_for :users, skip: [ :sessions, :registrations, :passwords, :confirmations, :unlocks ], controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"
  }
  devise_scope :user do
    delete "/users/sign_out", to: "devise/sessions#destroy"
  end

  get "up" => "rails/health#show", as: :rails_health_check

  # Development-only routes
  if Rails.env.development?
    post "/dev/impersonate", to: "dev#impersonate", as: :dev_impersonate
    post "/dev/clear_impersonation", to: "dev#clear_impersonation", as: :dev_clear_impersonation
  end

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  namespace :dashboard do
    resources :profile, only: [ :index ]

    namespace :server do
      resources :tags do
        collection do
          get :search
          get :by_name
        end
      end
    end

    namespace :admin do
      resources :config, only: [ :index ] do
        collection do
          post :update_discord_roles
          post :refresh_discord_roles
        end
      end
      resources :data, only: [ :index ] do
        member do
          get :inspect
        end
      end
      resources :bot, only: [ :index ] do
        collection do
          post :start
          post :stop
          post :restart
          post :force_stop
          get :status
          post :register_guild_commands
          post :register_global_commands
        end
      end
    end
  end

  get "/dashboard", to: "dashboard#index"

  # Defines the root path route ("/")
  root "home#index"
end
