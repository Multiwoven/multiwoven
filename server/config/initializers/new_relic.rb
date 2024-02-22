if ENV['NEW_RELIC_KEY'].present?
  NewRelic::Agent.manual_start(license_key: ENV['NEW_RELIC_KEY'])
end
