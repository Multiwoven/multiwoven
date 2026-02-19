# frozen_string_literal: true

module HostedDataStores
  class DeleteDataStore
    include Interactor

    HANDLERS = {
      "vector_store_hosted_connector" => HostedDataStores::Postgres::DeletePostgresHostDataStore
    }.freeze

    def call
      template_id = context.hosted_data_store.template_id
      workspace = context.workspace
      hosted_data_store = context.hosted_data_store
      class_name = HANDLERS[template_id] || raise("Invalid template id")
      result = class_name.new(workspace:, hosted_data_store:).delete_data_store
      raise "Failed to delete data store" unless result.destroyed?

      context.hosted_data_store = result
    rescue StandardError => e
      context.fail!(errors: e.message)
    end
  end
end
