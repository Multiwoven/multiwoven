# frozen_string_literal: true

require "rails_helper"

RSpec.describe Liquid::CustomFilters do
  include Liquid::CustomFilters

  describe ".cast" do
    it "casts input to string" do
      expect(cast(123, "string")).to eq("123")
    end

    it "casts input to number" do
      expect(cast("123.45", "number")).to eq(123.45)
    end

    it "casts non-numeric input to number as 0" do
      expect(cast("abc", "number")).to eq(0)
    end

    it "casts input to boolean" do
      expect(cast("true", "boolean")).to be true
    end
  end

  describe ".regex_replace" do
    it "replaces matching substrings" do
      expect(regex_replace("hello world", "world", "mars")).to eq("hello mars")
    end

    it "supports regex flags" do
      expect(regex_replace("Hello World", "world", "mars", "i")).to eq("Hello mars")
    end
  end

  describe ".to_datetime" do
    it "date format '%m/%d/%Y %H:%M'" do
      expect(to_datetime("1/26/2024 9:20", "%m/%d/%Y %H:%M")).to eq("2024-01-26T09:20:00+00:00")
    end

    it "date format '%m/%d/%Y %H:%M'" do
      expect(to_datetime("1/26/2024 9:20 AM", "%m/%d/%Y %H:%M")).to eq("2024-01-26T09:20:00+00:00")
    end
  end
end
