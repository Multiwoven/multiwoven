# frozen_string_literal: true

require "spec_helper"

PROVIDER_TYPES = %w[built_in cloud_provider partner_provider third_party].freeze
MODEL_TYPES = %w[llm embedding vision].freeze

RSpec.describe "AI Model connector JSON" do
  def ai_model_clients
    @ai_model_clients ||= Multiwoven::Integrations::ENABLED_SOURCES.filter_map do |name|
      client = Multiwoven::Integrations::Service.connector_class("Source", name).new
      client if client.meta_data[:data][:category] == "AI Model"
    end
  end

  def json_at(client, relative)
    path = File.join(File.dirname(Object.const_source_location(client.class.to_s).first), relative)
    File.exist?(path) ? JSON.parse(File.read(path)) : nil
  end

  def value_at(payload, dotted)
    dotted.to_s.split(".").reduce(payload) do |node, key|
      break if node.nil?

      node.is_a?(Array) ? node[Integer(key)] : node[key]
    end
  end

  before do
    allow(Multiwoven::Integrations::Core::OpenRouterCatalog).to receive(:fetch).and_return(
      Multiwoven::Integrations::Core::OpenRouterCatalog::Result.new(
        models_by_slug: {}, fetched_at: Time.now, source: "unavailable"
      )
    )
  end

  it "registers Google Gemini and John Snow Labs as ordinary sources" do
    expect(Multiwoven::Integrations::ENABLED_SOURCES).to include("GoogleGemini", "JohnSnowLabs")
  end

  describe "meta.json" do
    it "declares Model Hub taxonomy on every AI Model connector" do
      ai_model_clients.each do |client|
        meta = client.meta_data[:data]
        name = meta[:name]

        expect(PROVIDER_TYPES).to include(meta[:provider_type]), "#{name} has an unknown provider_type"
        expect(meta[:description]).to be_present, "#{name} is missing a description"
        expect(meta[:display_order]).to be_an(Integer), "#{name} is missing display_order"
      end
    end

    it "keeps display_order unique so the hub sort is stable" do
      orders = ai_model_clients.map { |client| client.meta_data[:data][:display_order] }

      expect(orders).to eq(orders.uniq)
    end

    it "opts only GenericOpenAI into editing the raw payload" do
      opted_in = ai_model_clients.select { |client| client.meta_data[:data][:show_payload_formats] }
                                 .map { |client| client.meta_data[:data][:name] }

      expect(opted_in).to eq(["GenericOpenAI"])
    end

    it "marks John Snow Labs as managed by AIS" do
      jsl = ai_model_clients.find { |client| client.meta_data[:data][:name] == "JohnSnowLabs" }

      expect(jsl.meta_data[:data][:managed_by_ais]).to be(true)
    end
  end

  describe "spec.json" do
    it "marks every AI Model connector as an ai_ml user-defined stream" do
      ai_model_clients.each do |client|
        spec = json_at(client, "config/spec.json")
        name = client.meta_data[:data][:name]

        expect(spec["connector_query_type"]).to eq("ai_ml"), "#{name} spec.json is not connector_query_type ai_ml"
        expect(spec["stream_type"]).to eq("user_defined"), "#{name} spec.json is not stream_type user_defined"
        expect(client.connector_spec.connector_query_type).to eq("ai_ml")
      end
    end

    it "flags sample payload fields so the form can hide or edit them" do
      ai_model_clients.each do |client|
        properties = json_at(client, "config/spec.json").dig("connection_specification", "properties") || {}
        name = client.meta_data[:data][:name]

        %w[request_format response_format].each do |field|
          property = properties[field]
          next if property.blank? || property["default"].blank?

          flag = field == "request_format" ? "x-request-format" : "x-response-format"
          expect(property[flag]).to eq(true), "#{name} #{field} has a default but is missing #{flag}"
        end
      end
    end

    it "keeps a declared dynamic input path inside the request_format default" do
      ai_model_clients.each do |client|
        spec = json_at(client, "config/spec.json")
        connection = spec.fetch("connection_specification")
        declared = connection["x-dynamic-input-path"]
        next if declared.blank?

        default = connection.dig("properties", "request_format", "default")
        expect(default).to be_present, "#{client.meta_data[:data][:name]} declares #{declared} but has no request_format default"

        payload = JSON.parse(default)
        expect(value_at(payload, declared)).not_to be_nil,
                                                   "#{client.meta_data[:data][:name]} x-dynamic-input-path #{declared} is absent from request_format.default"
      end
    end

    it "puts catalog inference paths on connection_specification, not the spec root" do
      ai_model_clients.each do |client|
        spec = json_at(client, "config/spec.json")
        name = client.meta_data[:data][:name]

        expect(spec).not_to have_key("x-dynamic-input-path"), "#{name} put x-dynamic-input-path at the spec root"
        expect(spec).not_to have_key("x-output-path"), "#{name} put x-output-path at the spec root"
      end
    end
  end

  describe "catalog.json" do
    it "ships a catalog every AI Model connector can discover" do
      ai_model_clients.each do |client|
        catalog = json_at(client, "config/catalog.json")
        name = client.meta_data[:data][:name]

        expect(catalog).to be_present, "#{name} is missing config/catalog.json"
        expect(catalog["request_rate_limit"]).to be_a(Integer), "#{name} catalog.json has no request_rate_limit"
        expect(%w[minute hour day]).to include(catalog["request_rate_limit_unit"]),
                                       "#{name} catalog.json has an unknown request_rate_limit_unit"
        expect(catalog["request_rate_concurrency"]).to be_a(Integer),
                                                       "#{name} catalog.json has no request_rate_concurrency"
        expect(catalog["streams"]).to be_an(Array), "#{name} catalog.json has no streams array"
      end
    end
  end

  describe "models.json" do
    it "uses a models array with the fields the hub reads" do
      ai_model_clients.each do |client|
        data = json_at(client, "config/models.json")
        next if data.nil?

        name = client.meta_data[:data][:name]
        expect(data["models"]).to be_an(Array), "#{name} models.json is missing a models array"
        expect(data["//models"]).not_to be_a(Array), "#{name} parked models under //models"

        data["models"].each do |model|
          expect(model["id"]).to be_present, "#{name} has a model with no id"
          expect(model["name"]).to be_present, "#{name} model #{model["id"]} has no name"
          expect(MODEL_TYPES).to include(model["model_type"]), "#{name} model #{model["id"]} has an unknown model_type"
          expect(model["tasks"]).to be_an(Array), "#{name} model #{model["id"]} has no tasks"
        end
      end
    end
  end
end
