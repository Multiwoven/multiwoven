Rails.application.routes.draw do
  # Health Check
  get "up" => "rails/health#show", as: :rails_health_check

  # API routes
  namespace :api do
    namespace :v1 do
      # Authentication Routes
      scope :auth do
        post 'signup', to: 'auth#signup'
        post 'verify_code', to: 'auth#verify_code'
        post 'login', to: 'auth#login'
        delete 'logout', to: 'auth#logout'
        post 'forgot_password', to: 'auth#forgot_password'
        post 'reset_password', to: 'auth#reset_password'
      end

      # Workspace Routes
      resources :workspaces
    end
  end

  # Uncomment below if you have a root path
  # root "posts#index"
end