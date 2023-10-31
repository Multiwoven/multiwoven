# frozen_string_literal: true

module Models
  class UpdateModel
    include Interactor

    def call
      unless context
             .model
             .update(context.model_params)
        context.fail!(errors: context.model.errors)
      end
    end
  end
end
