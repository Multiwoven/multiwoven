# frozen_string_literal: true

require "pathname"

module MultiwovenApp
  def self.root
    Pathname.new(File.expand_path("..", __dir__))
  end

  def self.enterprise?
    return if ENV.fetch("DISABLE_ENTERPRISE", false)

    @enterprise ||= root.join("enterprise").exist?
  end
end
