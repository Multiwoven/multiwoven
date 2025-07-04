# frozen_string_literal: true

module Admin
  # Using ActionController::Base instead of ApplicationController (which uses ActionController::API)
  # This allows us to use layouts, which aren't supported in API controllers
  class BaseController < ActionController::Base
    protect_from_forgery with: :exception
    # In API-only mode, we need to explicitly include these modules
    include ActionController::Cookies
    include ActionController::Flash
    layout 'admin'
    
    before_action :authenticate_super_admin!
    
    private
    
    def authenticate_super_admin!
      redirect_to admin_login_path unless super_admin_signed_in?
    end
    
    def super_admin_signed_in?
      session[:super_admin_id].present?
    end
    
    def current_super_admin
      @current_super_admin ||= SuperAdmin.find_by(id: session[:super_admin_id]) if super_admin_signed_in?
    end
    
    helper_method :super_admin_signed_in?, :current_super_admin
  end
end
