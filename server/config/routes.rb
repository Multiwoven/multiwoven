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
      post "verify_code", to: "auth#verify_code"
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
        end
      end
      resources :models
      resources :syncs do
        collection do
          get :configurations
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
      delete "schedule_syncs", to: "schedule_syncs#destroy"
    end
  end
<<<<<<< HEAD
=======
  if MultiwovenApp.enterprise?
    namespace :enterprise, defaults: { format: "json" } do
      namespace :api do
        namespace :v1 do
          post "invite_signup", to: "auth#invite_signup"
          resources :workspaces do
            resources :users do
              patch "update_role", on: :member
              patch "resend_invite", on: :member
              post "invite", on: :collection
            end
          end
          resources :roles, only: [:index]
          resources :resources, only: [:index]
          resource :profile, only: %i[update destroy]
        end
      end
    end
  end
>>>>>>> 29becf76 (feat(CE): Add Manual Sync Schedule controller (#281))

  # Uncomment below if you have a root path
  root "rails/health#show"
end
