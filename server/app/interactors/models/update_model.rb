# frozen_string_literal: true

module Models
  class UpdateModel
    include Interactor

    def call
      unless context
             .model
             .update(context.model_params)
        context.fail!(model: context.model)
      end
    end
  end
end
