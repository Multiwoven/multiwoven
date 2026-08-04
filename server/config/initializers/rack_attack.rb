class Rack::Attack
  ### Configure Cache ###

  # If you don't want to use Rails.cache (Rack::Attack's default), then
  # configure it here.
  #
  # Note: The store is only used for throttling (not blocklisting and
  # safelisting). It must implement .increment and .write like
  # ActiveSupport::Cache::Store

  # Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  ### Throttle Spammy Clients ###

  # If any single client IP is making tons of requests, then they're
  # probably malicious or a poorly-configured scraper. Either way, they
  # don't deserve to hog all of the app server's CPU. Cut them off!
  #
  # Note: If you're serving assets through rack, those requests may be
  # counted by rack-attack and this throttle may be activated too
  # quickly. If so, enable the condition to exclude them from tracking.

  # Throttle all requests by IP (60rpm)
  #
  # Key: "rack::attack:#{Time.now.to_i/:period}:req/ip:#{req.ip}"
  throttle('logins/ip', limit: 5, period: 20.seconds) do |req|
    if req.path == "/api/v1/login" && req.post?
      req.env['action_dispatch.remote_ip'].to_s
    end
  end

  throttle('sso_logins/ip', limit: 3, period: 20.seconds) do |req|
    if req.path == "/enterprise/api/v1/sso_login" && req.post?
      req.env['action_dispatch.remote_ip'].to_s
    end
  end

  throttle('signups/ip', limit: 2, period: 60.seconds) do |req|
    if req.path == "/api/v1/signup" && req.post?
      req.env['action_dispatch.remote_ip'].to_s
    end
  end

  throttle('forgot_password/ip', limit: 2, period: 60.seconds) do |req|
    if req.path == "/api/v1/forgot_password" && req.post?
      req.env['action_dispatch.remote_ip'].to_s
    end
  end

  throttle('reset_password/ip', limit: 2, period: 60.seconds) do |req|
    if req.path == "/api/v1/reset_password" && req.post?
      req.env['action_dispatch.remote_ip'].to_s
    end
  end

<<<<<<< HEAD
=======
  # Public, unauthenticated badge lookup — hit on every view of every app.
  throttle('agentic_badge/ip', limit: 120, period: 60.seconds) do |req|
    if req.get? && req.path.match?(%r{/agentic_coding/workspaces/[^/]+/apps/[^/]+/badge\z})
      req.env['action_dispatch.remote_ip'].to_s
    end
  end

  # Public, unauthenticated CSP frame-ancestors lookup called by the Node-side
  # security-headers middleware. Cache-TTL means each id is fetched at most
  # once per minute per Node, so 120 rpm/IP floors id-enumeration by scrapers.
  throttle('embed_origins_lookup/ip', limit: 120, period: 60.seconds) do |req|
    if req.get? && req.path == "/enterprise/api/v1/embed_origins/lookup"
      req.env['action_dispatch.remote_ip'].to_s
    end
  end

>>>>>>> 26ac41b53 (chore(CE): clickjacking issue solved (#2128))
  throttle('resend_verification/ip', limit: 2, period: 300.seconds) do |req|
    if req.path == '/api/v1/resend_verification' && req.post?
      req.env['action_dispatch.remote_ip'].to_s
    end
  end

  self.throttled_response = lambda do |env|
    matched = env['rack.attack.matched']
    match_data = env['rack.attack.match_data']
    retry_after = match_data[:period]

    message =
      case matched
      when "logins/ip"
        "Too many login attempts. Please try again in #{retry_after} seconds."
      when "sso_logins/ip"
        "Too many login attempts. Please try again in #{retry_after} seconds."
      when "signups/ip"
        "Too many signup attempts. Please wait #{retry_after} seconds before trying again."
      when "forgot_password/ip"
        "Too many password reset attempts. Please wait #{retry_after} seconds before trying again."
      when "reset_password/ip"
        "Too many password reset attempts. Please wait #{retry_after} seconds before trying again."
      when "resend_verification/ip"
        "Too many verification email requests. Please wait #{retry_after} seconds before trying again."
<<<<<<< HEAD
=======
      when "analytics/ip_app", "analytics/app"
        "Too many analytics requests. Please wait #{retry_after} seconds before trying again."
      when "embed_origins_lookup/ip"
        "Too many embed-origin lookups. Please wait #{retry_after} seconds before trying again."
>>>>>>> 26ac41b53 (chore(CE): clickjacking issue solved (#2128))
      else
        "Too many requests. Please try again later."
      end

    [
      429,
      {
        'Content-Type' => 'application/json',
        'Retry-After' => retry_after.to_s
      },
      [{ error: message }.to_json]
    ]
  end

  safelist('allow-localhost') do |req|
    %w[127.0.0.1 ::1].include?(req.ip)
  end
end