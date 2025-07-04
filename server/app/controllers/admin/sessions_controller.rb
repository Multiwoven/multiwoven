# frozen_string_literal: true

module Admin
  class SessionsController < Admin::BaseController
    skip_before_action :authenticate_super_admin!, only: [:new, :create]
    skip_before_action :verify_authenticity_token, only: [:create]
    layout 'admin_login', only: [:new, :create]
    
    def new
      redirect_to admin_users_path if session[:super_admin_id].present?
    end
    
    def create
      admin = SuperAdmin.authenticate(params[:email], params[:password])
      
      if admin
        session[:super_admin_id] = admin.id
        redirect_to admin_users_path
      else
        # Instead of using flash.now, pass the error message directly to the view
        @error_message = 'Invalid email or password'
        render :new, status: :unprocessable_entity
      end
    end
    
    def destroy
      session[:super_admin_id] = nil
      redirect_to admin_login_path
    end
  end
end
