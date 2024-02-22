# frozen_string_literal: true

require "simplecov"
require "simplecov_json_formatter"

SimpleCov.start "rails" do
  formatter SimpleCov::Formatter::JSONFormatter
  add_filter "/spec/"
end
