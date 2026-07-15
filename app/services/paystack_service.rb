require 'net/http'
require 'json'
require 'uri'

class PaystackService
  BASE_URL = "https://api.paystack.co"
  SECRET_KEY = ENV.fetch("PAYSTACK_SECRET_KEY", "")

  def self.initialize_payment(email:, amount:, reference:, metadata: {}, callback_url: nil)
    raise "PAYSTACK_SECRET_KEY not configured" if SECRET_KEY.blank?

    uri = URI("#{BASE_URL}/transaction/initialize")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 10
    http.write_timeout = 10

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{SECRET_KEY}"
    request["Content-Type"] = "application/json"
    payload = {
      email: email,
      amount: amount,
      reference: reference,
      metadata: metadata
    }
    payload[:callback_url] = callback_url if callback_url.present?

    request.body = JSON.generate(payload)

    response = http.request(request)
    JSON.parse(response.body)
  rescue StandardError => e
    Rails.logger.error("Paystack API Error: #{e.message}")
    { "status" => false, "message" => e.message }
  end

  def self.verify_payment(reference)
    raise "PAYSTACK_SECRET_KEY not configured" if SECRET_KEY.blank?

    uri = URI("#{BASE_URL}/transaction/verify/#{reference}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{SECRET_KEY}"

    response = http.request(request)
    JSON.parse(response.body)
  end

  def self.create_plan(name:, description:, amount:, interval: "monthly")
    raise "PAYSTACK_SECRET_KEY not configured" if SECRET_KEY.blank?

    uri = URI("#{BASE_URL}/plan")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{SECRET_KEY}"
    request["Content-Type"] = "application/json"
    request.body = JSON.generate({
      name: name,
      description: description,
      amount: amount,
      interval: interval
    })

    response = http.request(request)
    JSON.parse(response.body)
  end
end
