# frozen_string_literal: true

require "rubygems/package"
require "net/http"

# rubocop:disable Metrics/ClassLength
class SyncGeoLiteDbJob < ApplicationJob
  self.queue_adapter = :solid_queue
  queue_as :background
  GEOLITE_DB_NAME = "GeoLite2-City"
  GEOLITE_DOWNLOAD_URL = "https://download.maxmind.com/geoip/databases/#{GEOLITE_DB_NAME}/download".freeze
  LOCAL_PATH           = Rails.root.join("db/geo/#{GEOLITE_DB_NAME}.mmdb").freeze
  BLOB_FILENAME        = "#{GEOLITE_DB_NAME}.mmdb".freeze

  def perform
    unless ENV["MAXMIND_ACCOUNT_ID"].present? && ENV["MAXMIND_LICENSE_KEY"].present?
      Rails.logger.info("[SyncGeoLiteDbJob] MAXMIND_ACCOUNT_ID and MAXMIND_LICENSE_KEY are not set")
      return
    end

    blob = find_blob

    if up_to_date?(blob)
      Rails.logger.info("[SyncGeoLiteDbJob] #{GEOLITE_DB_NAME} is up to date, skipping download")
      return
    end

    download_from_maxmind_and_upload
    Rails.logger.info("[SyncGeoLiteDbJob] Uploaded new mmdb")
  rescue StandardError => e
    Rails.logger.error("[SyncGeoLiteDbJob] Error: #{e.message}")
  end

  def start_subscriber!
    Rails.logger.info("[SyncGeoLiteDbJob] Starting subscriber for GeoLite2 database...")
    polling_interval = ENV.fetch("GEOLITE_POLLING_INTERVAL_HOURLY", 1).hour.to_i
    Thread.new do
      last_seen = find_blob&.metadata&.dig("last_modified_at")
      Rails.logger.info("[SyncGeoLiteDbJob] Last seen mmdb last_modified_at: #{last_seen}")
      loop { last_seen = poll_for_update(last_seen, polling_interval) }
    rescue StandardError => e
      Rails.logger.error("[SyncGeoLiteDbJob] Subscriber thread crashed: #{e.message}")
    end
  end

  def initialize_geocoder
    if File.exist?(LOCAL_PATH)
      Geocoder.configure(
        ip_lookup: :geoip2,
        geoip2: { file: LOCAL_PATH.to_s }
      )
    else
      Rails.logger.info("[SyncGeoLiteDbJob] Local mmdb not found, skipping geocoder configuration")
    end
  rescue StandardError => e
    Rails.logger.error("[SyncGeoLiteDbJob] Error initializing geocoder: #{e.message}")
    raise
  end

  def download_to_local
    blob = find_blob
    unless blob
      Rails.logger.info("[SyncGeoLiteDbJob] No blob found in ActiveStorage, skipping download to local")
      return
    end

    Rails.logger.info("[SyncGeoLiteDbJob] Found blob from ActiveStorage, Downloading mmdb to local path: #{LOCAL_PATH}")

    FileUtils.mkdir_p(LOCAL_PATH.dirname)
    blob.open do |tmp|
      FileUtils.cp(tmp.path, LOCAL_PATH.to_s)
    end
  rescue StandardError => e
    Rails.logger.error("[SyncGeoLiteDbJob] Error downloading mmdb to local: #{e.message}")
    raise
  end

  private

  def poll_for_update(last_seen, interval)
    sleep interval
    current = find_blob&.metadata&.dig("last_modified_at")
    Rails.logger.info("[SyncGeoLiteDbJob] Current mmdb last modified at: #{current}")
    return last_seen if current == last_seen

    Rails.logger.info("[SyncGeoLiteDbJob] GeoLite2 database has been updated, downloading new mmdb...")
    begin
      download_to_local
      initialize_geocoder
      current
    rescue StandardError
      last_seen
    ensure
      ActiveRecord::Base.clear_query_cache
      ActiveRecord::Base.connection_pool.release_connection
    end
  end

  def up_to_date?(blob)
    return false unless blob

    remote_mtime = fetch_maxmind_last_modified
    stored_mtime = blob.metadata["last_modified_at"]&.then { |v| Time.zone.parse(v) }
    return false unless remote_mtime && stored_mtime

    remote_mtime <= stored_mtime
  end

  def find_blob
    ActiveStorage::Blob.find_by(filename: BLOB_FILENAME)
  end

  def fetch_maxmind_last_modified
    uri = build_uri("tar.gz")
    req = Net::HTTP::Head.new(uri)
    req.basic_auth(ENV["MAXMIND_ACCOUNT_ID"], ENV["MAXMIND_LICENSE_KEY"])
    build_http(uri).start { |h| h.request(req) }["last-modified"]
                   &.then { |v| Time.zone.parse(v) }
  rescue StandardError => e
    Rails.logger.info("[SyncGeoLiteDbJob] Could not check for updates: #{e.message}, proceeding with download")
    nil
  end

  def download_from_maxmind_and_upload
    uri = build_uri("tar.gz")
    req = Net::HTTP::Get.new(uri)
    req.basic_auth(ENV["MAXMIND_ACCOUNT_ID"], ENV["MAXMIND_LICENSE_KEY"])

    tar_tmp  = Tempfile.new(["geolite2", ".tar.gz"], binmode: true)
    mmdb_tmp = Tempfile.new(["geolite2", ".mmdb"], binmode: true)
    last_modified = nil

    follow_redirect(build_http(uri), req, tar_tmp) do |resp|
      last_modified = resp["last-modified"]&.then { |v| Time.zone.parse(v) }
    end
    tar_tmp.rewind
    extract_mmdb(tar_tmp, mmdb_tmp)
    mmdb_tmp.rewind

    old_blob = find_blob

    ActiveStorage::Blob.create_and_upload!(
      io: mmdb_tmp,
      filename: BLOB_FILENAME,
      content_type: "application/octet-stream",
      metadata: { last_modified_at: last_modified&.iso8601 }
    )
    old_blob&.purge
    last_modified
  rescue StandardError => e
    Rails.logger.error("[SyncGeoLiteDbJob] Error updating #{GEOLITE_DB_NAME} database: #{e.message}")
    raise
  ensure
    tar_tmp&.close!
    mmdb_tmp&.close!
  end

  def build_uri(suffix)
    URI(GEOLITE_DOWNLOAD_URL).tap { |u| u.query = URI.encode_www_form(suffix:) }
  end

  def build_http(uri)
    Net::HTTP.new(uri.host, uri.port).tap { |h| h.use_ssl = true }
  end

  def follow_redirect(http, request, tmp, limit = 5, &block)
    raise "Too many redirects" if limit.zero?

    http.start do |h|
      h.request(request) do |resp|
        case resp
        when Net::HTTPSuccess
          block&.call(resp)
          resp.read_body { |chunk| tmp.write(chunk) }
        when Net::HTTPRedirection
          new_uri  = URI(resp["location"])
          new_http = Net::HTTP.new(new_uri.host, new_uri.port).tap { |h2| h2.use_ssl = new_uri.scheme == "https" }
          follow_redirect(new_http, Net::HTTP::Get.new(new_uri), tmp, limit - 1, &block)
        else
          raise "Download failed: #{resp.code} #{resp.message}"
        end
      end
    end
  end

  def extract_mmdb(tar_gz_tmp, mmdb_tmp)
    Zlib::GzipReader.open(tar_gz_tmp.path) do |gz|
      Gem::Package::TarReader.new(gz) do |tar|
        tar.each do |entry|
          next unless entry.file? && entry.full_name.end_with?(".mmdb")

          mmdb_tmp.write(entry.read)
          break
        end
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
