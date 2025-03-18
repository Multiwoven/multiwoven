# frozen_string_literal: true

# Ensure that the lib directory is autoloaded by Rails
Rails.application.config.autoload_paths += %W[
  #{Rails.root}/app/lib
]
