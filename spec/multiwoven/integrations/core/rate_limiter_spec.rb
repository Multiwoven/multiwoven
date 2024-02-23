# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Core::RateLimiter do
  let(:sync_config) { instance_double("SyncConfig", stream: stream) }
  let(:stream) do
    instance_double("Stream",
                    request_rate_limit: 4,
                    rate_limit_unit_seconds: 1)
  end
  let(:records) { %w[record1 record2] }

  let(:limiter_class) do
    Class.new do
      prepend Multiwoven::Integrations::Core::RateLimiter

      define_method(:write) do |_sync_config, _records, _action = "insert"|
        puts "write called"
      end
    end.new
  end

  describe "#write" do
    it "should set the @queue and call super on calling write" do
      output = capture_stdout do
        limiter_class.write(sync_config, records)
      end

      queue = limiter_class.instance_variable_get(:@queue)
      expect(queue).not_to be_nil
      expect(queue).to be_a(Limiter::RateQueue)

      expect(queue.instance_variable_get(:@size)).to eq(stream.request_rate_limit)
      expect(queue.instance_variable_get(:@interval)).to eq(stream.rate_limit_unit_seconds)

      expect(output).to include("write called")
    end

    it "should set the @queue once and call super N times on calling write N times" do
      output = capture_stdout do
        5.times { limiter_class.write(sync_config, records) }
      end

      # expect(output.scan(/write called/).length).to eq(4)
      expect(output).to eq(
        "write called\nwrite called\nwrite called\nwrite called\nHit the limit, waiting\nwrite called\n"
      )
    end

    it "should print logs when ratelimiting hit" do
      output = capture_stdout do
        10.times { limiter_class.write(sync_config, records) }
      end
      expect(output.scan(/Hit the limit, waiting/).count).to eq(2)
    end
  end
end
