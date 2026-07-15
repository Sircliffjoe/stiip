require 'rails_helper'

RSpec.describe 'Api::V1::Companies', type: :request do
  let(:api_user) { User.create!(email: "api-companies@example.com", password: "password", first_name: "API", last_name: "User", confirmed_at: Time.current, role: :business_api) }
  let(:api_key) { api_user.api_keys.create!(name: "RSpec") }
  let(:headers) { { 'Authorization' => "Bearer #{api_key.plain_token}" } }

  describe 'GET /api/v1/companies' do
    it 'returns a successful response' do
      get '/api/v1/companies', headers: headers
      expect(response).to have_http_status(:success)
    end

    it 'rejects missing API keys' do
      get '/api/v1/companies'
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
