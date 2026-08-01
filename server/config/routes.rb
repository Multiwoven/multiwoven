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
          namespace :p2w do
            resources :workflows, only: [] do
              member do
                post :prompt
                get "events/:session_id", action: :events, as: :events
              end
            end
            post "sessions/:session_id/clarification", to: "workflows#clarification", as: :clarification
          end

          namespace :agents do
            resources :components, only: [:index]
            resources :tools do
              collection do
                get :definitions
                get "definitions/:definition_id", action: :show_definition, as: :show_definition
                post :check_connection
              end
              member do
                get :tool_list
              end
            end
            namespace :a2a do
              post :agent_card, to: "agents#agent_card"
            end
            resources :workflows do
              resources :workflow_runs, only: [:index] do
                collection do
                  get :export
                end
              end
              member do
                post :run
                post :prompt
              end
              resources :versions, only: [:index, :update, :destroy], controller: "workflow_versions" do
                member do
                  post :restore
                end
              end
              resources :files, only: [:index, :show, :create, :destroy], controller: "workflow_files"
              resources :sessions, only: [:index], controller: "workflow_sessions" do
                get "chat_messages", on: :member
              end
            end
            resources :workflow_approvals, only: [:index, :show] do
              member do
                post :resolve
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
          get "/sso/complete", to: "auth#sso_complete"
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
          resources :reports do
            collection do
              get :export
            end
          end
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

          namespace :agentic_coding do
            resources :workspaces, only: [] do
              resources :apps, only: [] do
                resource :badge, only: %i[show], controller: "app_badge"
              end
            end
            resources :templates, only: %i[index show]
            resources :agent_models, only: [:index]
            resources :apps do
              resource :settings, only: [:update] do
                resources :secrets, only: %i[index create update destroy]
                resource :database, only: %i[show create destroy] do
                  resources :tables, only: %i[index show], param: :name,
                                     constraints: { name: /[A-Za-z0-9_]+/ } do
                    resources :rows, only: %i[index create update destroy], param: :pk do
                      get :export, on: :collection
                    end
                  end
                end
                resource :storage, only: %i[show create destroy] do
                  get :refresh_credentials, on: :member
                  resources :folders, only: %i[index create destroy], param: :name,
                                     constraints: { name: /[a-z0-9][a-z0-9-]{1,61}[a-z0-9]/ },
                                     controller: "storage_folders" do
                    resources :files, only: %i[index create destroy], param: :key,
                                      constraints: { key: /[^\/]+/ },
                                      controller: "storage_files" do
                      get :presign, on: :member
                    end
                  end
                end
              end
              resources :app_users, only: %i[index destroy] do
                post "invite", on: :collection
                patch "resend_invite", on: :member
              end
              resources :deployments, only: [:index]
              resources :versions, only: %i[index update destroy], controller: "app_versions" do
                member do
                  post :restore
                  post :preview
                  delete :preview, action: :stop_preview
                end
              end
              resources :sessions, only: %i[show] do
                collection do
                  post :current
                end
                member do
                  get :events
                  get :diff
                  get :files
                  get :file_content
                  get :find
                  get :logs
                  post :write_file
                  get :questions
                  post "questions/:request_id/reply", action: :question_reply
                  post "questions/:request_id/reject", action: :question_reject
                end
                resources :prompts, only: [:create, :index]
                resources :deployments, only: [:create, :index, :show]
              end
            end

            resources :analytics do
              collection do
                post :track
              end
            end
          end

          namespace :internal do
            namespace :agentic_coding do
              resources :sandbox_images, only: [] do
                collection do
                  post "build", action: :build
                  get "build/:job_id", action: :build_status, as: :build_status
                end
              end
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

          resources :knowledge_bases, controller: "agents/knowledge_bases" do
            resources :knowledge_base_files, controller: "agents/knowledge_base_files"
          end

          resources :embed_origins, only: %i[index create update destroy] do
            collection { get :lookup }
          end
        end
      end
    end
  end
>>>>>>> bb0ec6d75 (chore(CE): added clickjacking frame ancestors header for security (#2124))

  # Uncomment below if you have a root path
  root "rails/health#show"
end
