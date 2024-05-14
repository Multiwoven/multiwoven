# frozen_string_literal: true

module Enterprise
  module Api
    module V1
      class RolesController < ApplicationController
        skip_before_action :validate_contract
        def index
          @roles = Role.all
          render json: @roles, status: :ok
        end
      end
    end
  end
end
