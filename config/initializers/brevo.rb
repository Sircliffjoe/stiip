# config/initializers/brevo.rb
require 'brevo'
require Rails.root.join('lib/brevo_delivery')

Brevo.configure do |config|
  config.api_key['api-key'] = ENV.fetch('BREVO_API_KEY', nil)
end

ActionMailer::Base.add_delivery_method :brevo_delivery, BrevoDelivery
