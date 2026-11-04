# frozen_string_literal: true

require "tiny_tds"

module Multiwoven::Integrations::Source
  module SqlServer
    include Multiwoven::Integrations::Core
    class Client < SourceConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        db = create_connection(connection_config)
        ConnectionStatus.new(
          status: ConnectionStatusType["succeeded"]
        ).to_multiwoven_message
      rescue TinyTds::Error => e
        ConnectionStatus.new(
          status: ConnectionStatusType["failed"],
          message: e.message
        ).to_multiwoven_message
      ensure
        db&.close
      end

      def discover(connection_config)
        connection_config = connection_config.with_indifferent_access
        schema = connection_config[:schema].presence || "dbo"
        query = "SELECT table_name, column_name, data_type, is_nullable
                 FROM information_schema.columns
                 WHERE table_schema = '#{escape(schema)}'
                 ORDER BY table_name, ordinal_position;"

        db = create_connection(connection_config)
        records = db.execute(query).map do |row|
          row.transform_keys { |key| key.to_s.downcase }
        end
        catalog = Catalog.new(streams: create_streams(records))
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(e, {
                           context: "SQLSERVER:DISCOVER:EXCEPTION",
                           type: "error"
                         })
      ensure
        db&.close
      end

      def read(sync_config)
        connection_config = sync_config.source.connection_specification.with_indifferent_access
        @pagination_primary_key = sync_config.model.primary_key
        query = sync_config.model.query
        query = batched_query(query, sync_config.limit, sync_config.offset) unless sync_config.limit.nil? && sync_config.offset.nil?

        db = create_connection(connection_config)

        query(db, query)
      rescue StandardError => e
        handle_exception(e, {
                           context: "SQLSERVER:READ:EXCEPTION",
                           type: "error",
                           sync_id: sync_config.sync_id,
                           sync_run_id: sync_config.sync_run_id
                         })
      ensure
        @pagination_primary_key = nil
        db&.close
      end

      def search(vector_search_config)
        connection_config = vector_search_config.source.connection_specification.with_indifferent_access
        query = vector_search_config[:vector]
        limit = vector_search_config[:limit]
        query = batched_query(query, limit, 0) unless limit.nil?

        db = create_connection(connection_config)
        query(db, query)
      rescue StandardError => e
        handle_exception(e, {
                           context: "SQLSERVER:SEARCH:EXCEPTION",
                           type: "error"
                         })
      ensure
        db&.close
      end

      private

      def query(connection, sql)
        connection.execute(reformat_query(sql)).map do |row|
          RecordMessage.new(data: row, emitted_at: Time.now.to_i).to_multiwoven_message
        end
      end

      # SQL Server does not support LIMIT/OFFSET; use OFFSET/FETCH NEXT.
      def batched_query(sql_query, limit, offset)
        offset = offset.to_i
        limit = limit&.to_i
        raise ArgumentError, "Offset and limit must be non-negative" if offset.negative? || (!limit.nil? && limit.negative?)

        sql_query = strip_trailing_terminator(sql_query)
        raise ArgumentError, "Query already contains a LIMIT clause" if clause_outside_literals?(sql_query, /\bLIMIT\s+\d+\b/i)
        raise ArgumentError, "Query already contains an OFFSET clause" if clause_outside_literals?(sql_query, /\bOFFSET\s+\d+\b/i)

        apply_pagination(sql_query, limit, offset)
      end

      # Convert Postgres/MySQL-style LIMIT/OFFSET (from upstream, including query_source) into SQL Server pagination.
      def reformat_query(sql_query)
        sql_query = strip_trailing_terminator(sql_query)

        return sql_query if clause_outside_literals?(sql_query, /\bOFFSET\s+\d+\s+ROWS\b/i)

        limit = nil
        offset = nil

        normalized = with_masked_literals(sql_query) do |masked|
          if (match = masked.match(/\bLIMIT\s+(\d+)\b/i))
            limit = match[1].to_i
            masked = masked.sub(/\bLIMIT\s+\d+\b/i, "")
          end

          if (match = masked.match(/\bOFFSET\s+(\d+)\b(?!\s+ROWS)/i))
            offset = match[1].to_i
            masked = masked.sub(/\bOFFSET\s+\d+\b(?!\s+ROWS)/i, "")
          end

          masked.gsub(/[^\S\n]+/, " ").strip
        end

        return normalized if limit.nil? && offset.nil?

        apply_pagination(normalized, limit, offset || 0)
      end

      def apply_pagination(sql_query, limit, offset)
        raise ArgumentError, "Limit must be at least 1" if !limit.nil? && limit.to_i < 1

        keys = normalize_primary_keys(@pagination_primary_key)
        has_order = clause_outside_literals?(sql_query, /\bORDER\s+BY\b/i)

        # query_source appends LIMIT without ORDER BY or primary_key metadata.
        # TOP does not require ORDER BY; OFFSET/FETCH does.
        return apply_top(sql_query, limit) if offset.to_i.zero? && !limit.nil? && !has_order && keys.empty?

        sql_query = ensure_stable_order(sql_query, keys: keys, has_order: has_order)

        clause = "OFFSET #{offset.to_i} ROWS"
        clause = "#{clause} FETCH NEXT #{limit.to_i} ROWS ONLY" unless limit.nil?

        "#{sql_query} #{clause}"
      end

      def apply_top(sql_query, limit)
        with_masked_literals(sql_query) do |masked|
          raise ArgumentError, "Query already contains TOP" if masked.match?(/\A\s*SELECT\s+(?:(?:DISTINCT|ALL)\s+)?TOP\b/i)

          pattern = /\A\s*SELECT\s+((?:DISTINCT|ALL)\s+)?/i
          raise ArgumentError, "Cannot apply TOP to this query; add ORDER BY" unless masked.match?(pattern)

          masked.sub(pattern) { "SELECT #{Regexp.last_match(1)}TOP #{limit.to_i} " }
        end
      end

      def ensure_stable_order(sql_query, keys:, has_order:)
        return append_order_tie_breakers(sql_query, keys) if has_order

        if keys.empty?
          raise ArgumentError,
                "Paginated SQL Server queries require an ORDER BY with a unique key, or a model primary_key"
        end

        "#{sql_query} ORDER BY #{order_by_list(keys)}"
      end

      def append_order_tie_breakers(sql_query, keys)
        missing = keys.reject { |key| order_by_includes_key?(sql_query, key) }
        return sql_query if missing.empty?

        "#{sql_query}, #{order_by_list(missing)}"
      end

      def order_by_includes_key?(sql_query, key)
        included = false
        with_masked_literals(sql_query) do |masked|
          order_clause = masked[/\bORDER\s+BY\b(.+)\z/im, 1]
          if order_clause
            quoted = Regexp.escape(quote_identifier(key))
            bare = Regexp.escape(key.to_s)
            included = order_clause.match?(/#{quoted}|\b#{bare}\b/i)
          end
          masked
        end
        included
      end

      def normalize_primary_keys(primary_key)
        Array(primary_key).flat_map { |key| key.to_s.split(",") }.map(&:strip).reject(&:empty?).uniq
      end

      def order_by_list(keys)
        keys.map { |key| quote_identifier(key) }.join(", ")
      end

      def quote_identifier(name)
        "[#{name.to_s.gsub("]", "]]")}]"
      end

      def strip_trailing_terminator(sql_query)
        with_masked_literals(sql_query.to_s.strip) do |masked|
          masked = masked.rstrip
          masked = masked.chomp(";") while masked.end_with?(";")
          masked
        end
      end

      def clause_outside_literals?(sql_query, pattern)
        matched = false
        with_masked_literals(sql_query) do |masked|
          matched = masked.match?(pattern)
          masked
        end
        matched
      end

      # Mask single-quoted SQL literals (including N'...' and escaped '') so rewrites
      # do not touch values like 'a;b' or 'LIMIT 1'.
      def with_masked_literals(sql_query)
        literals = []
        masked = sql_query.to_s.gsub(/(?:N)?'(?:''|[^'])*'/i) do |literal|
          literals << literal
          "__SQL_LITERAL_#{literals.length - 1}__"
        end

        result = yield(masked)
        literals.each_with_index do |literal, index|
          result = result.gsub("__SQL_LITERAL_#{index}__", literal)
        end
        result
      end

      def create_connection(connection_config)
        raise "Unsupported Auth type" unless connection_config[:credentials][:auth_type] == "username/password"

        TinyTds::Client.new(
          username: connection_config[:credentials][:username],
          password: connection_config[:credentials][:password],
          host: connection_config[:host],
          port: connection_config[:port].presence || 1433,
          database: connection_config[:database],
          timeout: 10,
          azure: connection_config[:azure].presence || false
        )
      end

      def create_streams(records)
        group_by_table(records).map do |r|
          Multiwoven::Integrations::Protocol::Stream.new(name: r[:tablename], action: StreamAction["fetch"], json_schema: convert_to_json_schema(r[:columns]))
        end
      end

      def group_by_table(records)
        records.group_by { |entry| entry["table_name"] }.map do |table_name, columns|
          {
            tablename: table_name,
            columns: columns.map do |column|
              {
                column_name: column["column_name"],
                type: column["data_type"],
                optional: column["is_nullable"] == "YES"
              }
            end
          }
        end
      end

      def escape(value)
        value.to_s.gsub("'", "''")
      end
    end
  end
end
