# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncGeoLiteDbJob, type: :job do
  let(:account_id)   { "123456" }
  let(:license_key)  { "test_license_key" }
  let(:remote_mtime) { 1.week.ago }
  let(:stored_mtime) { 2.weeks.ago }
  let(:blob)         { instance_double(ActiveStorage::Blob, metadata: { "last_modified_at" => stored_mtime.iso8601 }) }
  let(:job)          { described_class.new }

  before do
    stub_const("ENV", ENV.to_h.merge(
                        "MAXMIND_ACCOUNT_ID" => account_id,
                        "MAXMIND_LICENSE_KEY" => license_key
                      ))
  end

  describe "#perform" do
    context "when credentials are missing" do
      before { stub_const("ENV", ENV.to_h.except("MAXMIND_ACCOUNT_ID", "MAXMIND_LICENSE_KEY")) }

      it "returns early without downloading" do
        expect(ActiveStorage::Blob).not_to receive(:find_by)
        job.perform
      end
    end

    context "when no blob exists in ActiveStorage" do
      before do
        allow(ActiveStorage::Blob).to receive(:find_by).with(filename: described_class::BLOB_FILENAME).and_return(nil)
        allow(job).to receive(:download_from_maxmind_and_upload).and_return(nil)
      end

      it "proceeds with download" do
        job.perform
        expect(job).to have_received(:download_from_maxmind_and_upload)
      end
    end

    context "when blob is up to date" do
      before do
        allow(ActiveStorage::Blob).to receive(:find_by).with(filename: described_class::BLOB_FILENAME).and_return(blob)
        allow(job).to receive(:up_to_date?).and_return(true)
      end

      it "skips download" do
        expect(job).not_to receive(:download_from_maxmind_and_upload)
        job.perform
      end
    end

    context "when blob is outdated" do
      before do
        allow(ActiveStorage::Blob).to receive(:find_by).with(filename: described_class::BLOB_FILENAME).and_return(blob)
        allow(job).to receive(:fetch_maxmind_last_modified).and_return(remote_mtime)
        allow(job).to receive(:download_from_maxmind_and_upload).and_return(remote_mtime)
      end

      it "downloads the update" do
        job.perform
        expect(job).to have_received(:download_from_maxmind_and_upload)
      end
    end

    context "when MaxMind HEAD request fails (returns nil)" do
      before do
        allow(ActiveStorage::Blob).to receive(:find_by).with(filename: described_class::BLOB_FILENAME).and_return(blob)
        allow(job).to receive(:fetch_maxmind_last_modified).and_return(nil)
        allow(job).to receive(:download_from_maxmind_and_upload).and_return(nil)
      end

      it "proceeds with download (fail open)" do
        job.perform
        expect(job).to have_received(:download_from_maxmind_and_upload)
      end
    end

    context "when stored last_modified_at metadata is nil" do
      let(:blob) { instance_double(ActiveStorage::Blob, metadata: {}) }

      before do
        allow(ActiveStorage::Blob).to receive(:find_by).with(filename: described_class::BLOB_FILENAME).and_return(blob)
        allow(job).to receive(:fetch_maxmind_last_modified).and_return(remote_mtime)
        allow(job).to receive(:download_from_maxmind_and_upload).and_return(nil)
      end

      it "proceeds with download" do
        job.perform
        expect(job).to have_received(:download_from_maxmind_and_upload)
      end
    end

    context "when an error occurs" do
      before do
        allow(ActiveStorage::Blob).to receive(:find_by).and_raise(StandardError, "boom")
      end

      it "rescues and logs without re-raising" do
        expect { job.perform }.not_to raise_error
      end
    end
  end

  describe "#initialize_geocoder" do
    context "when the local mmdb file exists" do
      before { allow(File).to receive(:exist?).with(described_class::LOCAL_PATH).and_return(true) }

      it "configures Geocoder with geoip2 and the local path" do
        expect(Geocoder).to receive(:configure).with(
          ip_lookup: :geoip2,
          geoip2: { file: described_class::LOCAL_PATH.to_s }
        )
        job.initialize_geocoder
      end
    end

    context "when the local mmdb file does not exist" do
      before { allow(File).to receive(:exist?).with(described_class::LOCAL_PATH).and_return(false) }

      it "does not configure Geocoder" do
        expect(Geocoder).not_to receive(:configure)
        job.initialize_geocoder
      end
    end

    context "when Geocoder.configure raises" do
      before do
        allow(File).to receive(:exist?).with(described_class::LOCAL_PATH).and_return(true)
        allow(Geocoder).to receive(:configure).and_raise(StandardError, "config error")
      end

      it "logs and re-raises the error" do
        expect(Rails.logger).to receive(:error).with(/Error initializing geocoder/)
        expect { job.initialize_geocoder }.to raise_error(StandardError, "config error")
      end
    end
  end

  describe "#start_subscriber!" do
    it "returns a Thread" do
      thread = job.start_subscriber!
      thread.kill
      expect(thread).to be_a(Thread)
    end

    context "when GEOLITE_POLLING_INTERVAL_HOURLY is set" do
      before do
        allow(ENV).to receive(:fetch).with("GEOLITE_POLLING_INTERVAL_HOURLY", 1).and_return(1)
        allow(ActiveStorage::Blob).to receive(:find_by).and_return(nil)
      end

      it "uses the configured interval for polling" do
        observed_interval = nil
        allow(job).to receive(:sleep) do |n|
          observed_interval = n
          raise StopIteration
        end
        job.start_subscriber!.join(1)
        expect(observed_interval).to eq(1.hour.to_i)
      end
    end

    context "when blob metadata changes between polls" do
      let(:old_mtime) { "2024-01-10T12:00:00Z" }
      let(:new_mtime) { "2024-01-15T12:00:00Z" }

      it "calls download_to_local and initialize_geocoder when metadata changes" do
        call_count = 0
        allow(ActiveStorage::Blob).to receive(:find_by).with(filename: described_class::BLOB_FILENAME) do
          call_count += 1
          mtime = call_count == 1 ? old_mtime : new_mtime
          instance_double(ActiveStorage::Blob, metadata: { "last_modified_at" => mtime })
        end

        iteration = 0
        allow(job).to receive(:sleep) do
          iteration += 1
          throw :done if iteration >= 2
        end
        allow(job).to receive(:download_to_local)
        allow(job).to receive(:initialize_geocoder)

        catch(:done) do
          blob_filename = described_class::BLOB_FILENAME
          last_seen = ActiveStorage::Blob.find_by(filename: blob_filename)&.metadata&.dig("last_modified_at")
          loop do
            job.send(:sleep, 30)
            current = ActiveStorage::Blob.find_by(filename: blob_filename)&.metadata&.dig("last_modified_at")
            next if current == last_seen

            job.send(:download_to_local)
            job.send(:initialize_geocoder)
            last_seen = current
          end
        end

        expect(job).to have_received(:download_to_local).once
        expect(job).to have_received(:initialize_geocoder).once
      end
    end

    context "when download_to_local raises during a poll" do
      let(:old_mtime) { "2024-01-10T12:00:00Z" }
      let(:new_mtime) { "2024-01-15T12:00:00Z" }

      it "does not update last_seen and continues the loop" do
        call_count = 0
        allow(ActiveStorage::Blob).to receive(:find_by).with(filename: described_class::BLOB_FILENAME) do
          call_count += 1
          mtime = call_count == 1 ? old_mtime : new_mtime
          instance_double(ActiveStorage::Blob, metadata: { "last_modified_at" => mtime })
        end

        iteration = 0
        allow(job).to receive(:sleep) do
          iteration += 1
          throw :done if iteration >= 2
        end
        allow(job).to receive(:download_to_local).and_raise(StandardError, "storage error")
        allow(job).to receive(:initialize_geocoder)

        last_seen = old_mtime
        catch(:done) do
          blob_filename = described_class::BLOB_FILENAME
          loop do
            job.send(:sleep, 30)
            current = ActiveStorage::Blob.find_by(filename: blob_filename)&.metadata&.dig("last_modified_at")
            next if current == last_seen

            begin
              job.send(:download_to_local)
              job.send(:initialize_geocoder)
            rescue StandardError
              next
            end
            last_seen = current
          end
        end

        expect(last_seen).to eq(old_mtime)
        expect(job).not_to have_received(:initialize_geocoder)
      end
    end
  end

  describe "#download_to_local (private)" do
    context "when no blob exists in ActiveStorage" do
      before do
        allow(ActiveStorage::Blob).to receive(:find_by).with(filename: described_class::BLOB_FILENAME).and_return(nil)
      end

      it "returns without downloading" do
        expect { job.send(:download_to_local) }.not_to raise_error
      end
    end

    context "when a blob exists" do
      let(:tmp_file) { Tempfile.new("mmdb") }

      before do
        allow(ActiveStorage::Blob).to receive(:find_by).with(filename: described_class::BLOB_FILENAME).and_return(blob)
        allow(blob).to receive(:open).and_yield(tmp_file)
        allow(FileUtils).to receive(:mkdir_p)
        allow(FileUtils).to receive(:cp)
      end

      after { tmp_file.close! }

      it "creates the directory and copies the blob to LOCAL_PATH" do
        job.send(:download_to_local)
        expect(FileUtils).to have_received(:mkdir_p).with(described_class::LOCAL_PATH.dirname)
        expect(FileUtils).to have_received(:cp).with(tmp_file.path, described_class::LOCAL_PATH.to_s)
      end
    end

    context "when blob.open raises" do
      before do
        allow(ActiveStorage::Blob).to receive(:find_by).with(filename: described_class::BLOB_FILENAME).and_return(blob)
        allow(blob).to receive(:open).and_raise(StandardError, "storage error")
        allow(FileUtils).to receive(:mkdir_p)
      end

      it "logs and re-raises the error" do
        expect(Rails.logger).to receive(:error).with(/Error downloading mmdb to local/)
        expect { job.send(:download_to_local) }.to raise_error(StandardError, "storage error")
      end
    end
  end

  describe "#up_to_date? (private)" do
    context "when blob is nil" do
      it { expect(job.send(:up_to_date?, nil)).to be false }
    end

    context "when blob exists" do
      before { allow(job).to receive(:fetch_maxmind_last_modified).and_return(remote_mtime) }

      context "and remote is newer than stored" do
        it { expect(job.send(:up_to_date?, blob)).to be false }
      end

      context "and remote is older or equal to stored" do
        let(:remote_mtime) { 3.weeks.ago }

        it { expect(job.send(:up_to_date?, blob)).to be true }
      end

      context "and stored metadata is missing" do
        let(:blob) { instance_double(ActiveStorage::Blob, metadata: {}) }

        it { expect(job.send(:up_to_date?, blob)).to be false }
      end
    end

    context "when fetch_maxmind_last_modified returns nil (network error)" do
      before { allow(job).to receive(:fetch_maxmind_last_modified).and_return(nil) }

      it { expect(job.send(:up_to_date?, blob)).to be false }
    end
  end
end
