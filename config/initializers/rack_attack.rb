class Rack::Attack
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  # Safelist local requests
  safelist('allow-localhost') do |req|
    '127.0.0.1' == req.ip || '::1' == req.ip
  end

  # Allow an IP address to make 100 requests every 5 minutes
  throttle('req/ip', limit: 100, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?('/assets')
  end

  # Allow an IP to make 5 login attempts every 20 seconds
  throttle('logins/ip', limit: 5, period: 20.seconds) do |req|
    if req.path == '/users/sign_in' && req.post?
      req.ip
    end
  end

  # Throttle API requests by IP
  throttle('api/ip', limit: 300, period: 5.minutes) do |req|
    if req.path.start_with?('/api/v1/')
      req.ip
    end
  end
end
