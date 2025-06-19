# frozen_string_literal: true

module Admin
  class UsersController < Admin::BaseController
    skip_before_action :verify_authenticity_token, only: [:reset_password, :update_password, :update]
    before_action :find_user, only: [:show, :edit, :update, :simulate_request_login, :reset_password, :update_password]

    def index
      @users = User.order(created_at: :desc)
      
      # Search by keyword if provided
      if params[:keyword].present?
        @keyword = params[:keyword].strip
        @users = @users.where("email ILIKE :search OR name ILIKE :search", search: "%#{@keyword}%")
      end
      
      # Pagination
      @users = @users.page(params[:page]).per(50)
    end

    def show
      # Transfer any messages from session to instance variables for display
      @error_message = session.delete(:error_message)
      @success_message = session.delete(:success_message)
    end

    def edit
    end

    def update
      # Accept POST method for update as well as PATCH/PUT
      if @user.update(user_params)
        session[:success_message] = 'User was successfully updated.'
        redirect_to admin_user_path(@user)
      else
        # For render, set instance variable directly
        @error_message = @user.errors.full_messages.to_sentence
        render :edit, status: :unprocessable_entity
      end
    end

    def simulate_request_login
      # Generate a unique token that hasn't been allocated to any user
      token = nil
      loop do
        # Generate a secure random token
        token = SecureRandom.urlsafe_base64(32)
        # Check that this token isn't already used
        break unless User.exists?(simulate_req_token: token)
      end
      
      # Save the token to the user
      if @user.update(simulate_req_token: token)
        # Determine the frontend URL using UI_HOST environment variable
        frontend_url = ENV['UI_HOST'] || 'localhost:8000'
        # Ensure the URL has http/https prefix
        unless frontend_url.start_with?('http://', 'https://')
          frontend_url = "http://#{frontend_url}"
        end
        
        # Log the URL we're using for debugging
        Rails.logger.info "Redirecting to simulate endpoint with token"
        
        # Construct the redirect URL with the token
        redirect_url = "#{frontend_url}/users/simulate?token=#{@user.simulate_req_token}"
        
        # Redirect to the frontend app endpoint
        redirect_to redirect_url, allow_other_host: true
      else
        session[:error_message] = "Failed to generate token: #{@user.errors.full_messages.join(', ')}"
        redirect_back(fallback_location: admin_users_path)
      end
    end

    def reset_password
      # Transfer any messages from session to instance variables for display
      @error_message = session.delete(:error_message)
      @success_message = session.delete(:success_message)
    end

    def update_password
      # User is already set by find_user callback
      new_password = params[:user][:new_password]
      password_confirmation = params[:user][:password_confirmation]
      if new_password.blank? || password_confirmation.blank?
        session[:error_message] = "Password fields cannot be blank"
        redirect_back(fallback_location: root_path) and return
      end
      if new_password != password_confirmation
        session[:error_message] = "Password confirmation does not match"
        redirect_back(fallback_location: root_path) and return
      end
      if @user.update(password: new_password, password_confirmation: password_confirmation)
        session[:success_message] = "Password updated successfully"
        redirect_to admin_users_reset_password_path(@user.id) # replace with actual path
      else
        session[:error_message] = @user.errors.full_messages.join(", ")
        redirect_back(fallback_location: root_path)
      end
    end

    private
    
    def find_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:name, :email, :status)
    end
  end
end
