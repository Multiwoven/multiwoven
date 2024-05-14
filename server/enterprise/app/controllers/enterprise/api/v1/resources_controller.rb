# frozen_string_literal: true

module Enterprise
  module Api
    module V1
      class ResourcesController < ApplicationController
        skip_before_action :validate_contract
        def index
          @resources = Resource.all
          render json: @resources, status: :ok
        end
      end
    end
  end
end
