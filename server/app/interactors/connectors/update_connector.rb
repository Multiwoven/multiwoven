# frozen_string_literal: true

module Connectors
  class UpdateConnector
    include Interactor

    def call
      unless context.connector
                    .update(context.connector_params)
        context.fail!(connector: context.connector)
      end
    end
  end
end
