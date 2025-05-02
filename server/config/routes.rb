# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users
  # Health Check
  get "up" => "rails/health#show", as: :rails_health_check

  # API routes
  namespace :api do
    namespace :v1 do
      # Authentication Routes
      post "signup", to: "auth#signup"
      get "verify_user", to: "auth#verify_user"
      post "login", to: "auth#login"
      delete "logout", to: "auth#logout"
      post "forgot_password", to: "auth#forgot_password"
      post "reset_password", to: "auth#reset_password"
      post "resend_verification", to: "auth#resend_verification"

      # Workspace Routes
      resources :workspaces
      resources :connectors do
        member do
          get :discover
          post :query_source
          post :execute_model
        end
      end
      resources :catalogs, only: %i[create update]
      resources :models
      resources :syncs do
        collection do
          get :configurations
        end
        member do
          patch :enable
        end
        resources :sync_runs, only: %i[index show] do
          resources :sync_records, only: [:index]
        end
      end
      resources :connector_definitions, only: %i[index show] do
        collection do
          post :check_connection
        end
      end
      resources :users, only: [] do
        collection do
          get :me
        end
      end
      resources :reports do
        collection do
          get :workspace_activity
        end
      end

      post "schedule_syncs", to: "schedule_syncs#create"
      delete "schedule_syncs/:sync_id", to: "schedule_syncs#destroy"
    end
  end

  # Uncomment below if you have a root path
  root "rails/health#show"
end
