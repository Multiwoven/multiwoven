Rails.application.routes.draw do
  devise_for :users
  # Health Check
  get "up" => "rails/health#show", as: :rails_health_check

  # API routes
  namespace :api do
    namespace :v1 do
      # Authentication Routes
      post 'signup', to: 'auth#signup'
      post 'verify_code', to: 'auth#verify_code'
      post 'login', to: 'auth#login'
      delete 'logout', to: 'auth#logout'
      post 'forgot_password', to: 'auth#forgot_password'
      post 'reset_password', to: 'auth#reset_password'
      post 'resend_verification', to: 'auth#resend_verification'

      # Workspace Routes
      resources :workspaces do
        resources :workspace_users, only: [:create, :index, :update, :destroy]
      end
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
        resources :sync_runs, only: [:index, :show] do
          resources :sync_records, only: [:index]
        end
      end
      resources :connector_definitions, only: [:index, :show] do
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
    end
  end

  # Uncomment below if you have a root path
  root "rails/health#show"
end
