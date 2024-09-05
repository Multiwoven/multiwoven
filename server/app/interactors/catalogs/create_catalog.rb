# frozen_string_literal: true

module Catalogs
  class CreateCatalog
    include Interactor

    DEFAULT_URL = "unknown"
    DEFAULT_BATCH_SUPPORT = false
    DEFAULT_BATCH_SIZE = 0
    DEFAULT_REQUEST_METHOD = "POST"

    def call
      validate_catalog_params!
      catalog = build_catalog
      catalog.save

      if catalog.persisted?
        context.catalog = catalog
      else
        context.fail!(error: "Failed to persist catalog", catalog:)
      end
    end

    private

    def validate_catalog_params!
      context.catalog_params = context.catalog_params.with_indifferent_access
      return if context.catalog_params[:json_schema].present?

      context.fail!(error: "json_schema must be present in catalog_params")
    end

    def build_catalog
      context.connector.build_catalog(
        workspace_id: context.connector.workspace_id,
        catalog: catalog_params,
        catalog_hash: generate_catalog_hash
      )
    end

    def catalog_params
      {
        streams: [build_stream_params],
        request_rate_concurrency:,
        request_rate_limit:,
        request_rate_limit_unit:
      }
    end

    def build_stream_params
      {
        name: stream_name,
        url: stream_url,
        json_schema: context.catalog_params[:json_schema],
        batch_support:,
        batch_size:,
        request_method:
      }
    end

    def stream_name
      context.catalog_params[:name] || context.connector.name
    end

    def stream_url
      context.catalog_params[:url] || DEFAULT_URL
    end

    def batch_support
      context.catalog_params[:batch_support] || DEFAULT_BATCH_SUPPORT
    end

    def batch_size
      context.catalog_params[:batch_size] || DEFAULT_BATCH_SIZE
    end

    def request_method
      context.catalog_params[:request_method] || DEFAULT_REQUEST_METHOD
    end

    def request_rate_concurrency
      context.catalog_params[:request_rate_concurrency] || default_catalog[:request_rate_concurrency]
    end

    def request_rate_limit
      context.catalog_params[:request_rate_limit] || default_catalog[:request_rate_limit]
    end

    def request_rate_limit_unit
      context.catalog_params[:request_rate_limit_unit] || default_catalog[:request_rate_limit_unit]
    end

    def generate_catalog_hash
      Digest::SHA1.hexdigest(catalog_params.to_s)
    end

    def default_catalog
      @default_catalog ||= context.connector.pull_catalog
    end
  end
end
