# frozen_string_literal: true

module EmbedOrigins
  class Registry
    EMPTY_SET = Set.new.freeze
    REFRESH_INTERVAL_SECONDS = ENV.fetch("EMBED_ORIGINS_REFRESH_INTERVAL_SECONDS", "60").to_i
    def self.propagation_meta
      {
        refresh_interval_seconds: REFRESH_INTERVAL_SECONDS,
        message: "This change will start reflecting after #{REFRESH_INTERVAL_SECONDS} seconds."
      }
    end

    def self.normalize_origin(raw)
      s = raw.to_s.strip
      return nil if s.empty?

      s = s.chomp("/")
      # Downcase only the scheme+host, preserve any :port as-is.
      if (m = s.match(%r{\A(https?)://([^/]+)\z}i))
        "#{m[1].downcase}://#{m[2].downcase}"
      else
        s
      end
    end

    class << self
      def allowlist_for(workspace_id)
        snapshot[:by_workspace][workspace_id] || EMPTY_SET
      end

      def workspace_id_for_data_app(data_app_id)
        snapshot[:data_app][data_app_id.to_i]
      end

      def allowed?(workspace_id, origin)
        return false if origin.blank?
        return true if allowlist_for(workspace_id).include?(origin)

        snapshot[:global_matchers].any? { |m| matcher_hits?(m, origin) }
      end

      def refresh!
        @snapshot = build_snapshot
        Rails.logger.info(
          "[EmbedOrigins::Registry] snapshot refreshed " \
          "workspaces=#{@snapshot[:by_workspace].size} " \
          "data_apps=#{@snapshot[:data_app].size} " \
          "global_matchers=#{@snapshot[:global_matchers].size}"
        )
      end

      private

      def snapshot
        @snapshot ||= build_snapshot
      end

      def matcher_hits?(matcher, origin)
        return true                      if matcher == "*"
        return matcher.match?(origin)    if matcher.is_a?(Regexp)

        matcher == origin
      end

      def build_snapshot
        by_workspace = Hash.new { |h, k| h[k] = Set.new }
        org_wide     = Hash.new { |h, k| h[k] = Set.new }

        UserEmbedOrigin.find_each do |row|
          origin = Registry.normalize_origin(row.origin)
          next if origin.nil?

          if row.workspace_id
            by_workspace[row.workspace_id] << origin
          else
            org_wide[row.organization_id] << origin
          end
        end

        unless org_wide.empty?
          Workspace.where(organization_id: org_wide.keys)
                   .pluck(:id, :organization_id)
                   .each do |ws_id, org_id|
            by_workspace[ws_id].merge(org_wide[org_id])
          end
        end

        by_workspace.each_value(&:freeze)
        by_workspace.default_proc = nil
        {
          by_workspace: by_workspace.freeze,
          data_app: build_data_app_map.freeze,
          global_matchers: build_global_matchers.freeze
        }.freeze
      end

      def build_global_matchers
        return [] unless defined?(::CorsOriginParser)

        ::CorsOriginParser.configured_matchers
      end

      def build_data_app_map
        published_workflow_ids = Agents::Workflow.where(status: :published).pluck(:id)
        workflow_data_app_ids  = VisualComponent
                                 .where(configurable_type: "Agents::Workflow",
                                        configurable_id: published_workflow_ids)
                                 .distinct
                                 .pluck(:data_app_id)

        DataApp.where(status: :active)
               .or(DataApp.where(id: workflow_data_app_ids))
               .pluck(:id, :workspace_id)
               .to_h
      end
    end
  end
end
