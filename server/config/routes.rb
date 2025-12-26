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
<<<<<<< HEAD
=======
  if MultiwovenApp.enterprise?
    namespace :enterprise, defaults: { format: "json" } do
      namespace :api do
        namespace :v1 do
          namespace :agents do
            resources :components, only: [:index]
            resources :tools do
              collection do
                get :definitions
              end
            end
            resources :workflows do
              resources :workflow_runs, only: [:index] do
                collection do
                  get :export
                end
              end
              member do
                post :run
              end
            end
            resources :workflow_templates, only: [:index, :show]
            resources :workflow_logs, only: [:show]
            resources :remote_code_executions, only: [] do
              collection do
                post :execute
              end
            end
            resources :workflow_integrations do
              member do
                get :authenticate_app
                post :run
                post :message_feedback
              end
            end
          end
          get "data_apps_runner", to: "data_apps_runner#runner_script"
          post "invite_signup", to: "auth#invite_signup"
          post "sso_login", to: "auth#sso_login"
          post "/saml/idpresponse", to: "auth#acs_callback"
          resources :workspaces do
            resources :users do
              patch "update_role", on: :member
              patch "resend_invite", on: :member
              post "invite", on: :collection
              patch "accept_eula", on: :member
            end
          end
          resources :roles, only: %i[index create update destroy] do
            collection do
              get :resources
            end
          end
          resources :resources, only: [:index]
          resource :profile, only: %i[update destroy]
          resources :alerts
          resources :alert_media, only: %[index]
          resources :syncs do
            post "test", on: :member
            post "export", on: :member
          end
          resources :data_apps do
            post "preview", on: :collection
            post "fetch_data", on: :member
            post "fetch_data_stream", on: :member
            post "write_data", on: :member
            resources :feedbacks, only: [:create, :index, :update] do
              member do
                patch 'submit_additional_remarks'
              end
              collection do
                get :export
              end
            end
            resources :message_feedbacks, only: [:create, :index, :update] do
              collection do
                get :export
              end
            end
          end
          resources :audit_logs do
            get :audit_logs
          end
          resources :export_audit_logs do
            get :export_audit_logs
          end
          resources :reports
          resources :custom_visual_component, only: [:create, :show]
          resources :embeddings do
            collection do
              get :configuration
            end
          end

          resources :billing do
            collection do
              get :plans
              get :usage
            end
          end

          resources :sso_configurations do
            member do
              patch :enable
            end
          end

          resources :eulas do
            member do
              patch :enable
            end
          end

          resources :workspaces do
            member do
              post :upload_logo
              delete :destroy_logo
            end
          end

          resources :organizations do
            collection do
              post :upload_logo
              delete :destroy_logo
            end
          end

          resources :data_app_sessions do
            get "chat_messages", on: :member
            patch "update_title", on: :member
          end

          resources :hosted_datastore, controller: "hosted_data_stores" do
            collection do
              get :templates
            end
            member do
              patch :enable
            end
            resources :hosted_datastore_tables, controller: "hosted_data_store_tables"
          end
        end
      end
    end
  end
>>>>>>> 020d6654 (chore(CE): Tool model (#1543))

  # Uncomment below if you have a root path
  root "rails/health#show"
end
