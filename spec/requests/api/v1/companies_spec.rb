require 'rails_helper'

RSpec.describe 'Api::V1::Companies', type: :request do
  let(:headers) { { 'Authorization' => 'Bearer test_token' } }

  describe 'GET /api/v1/companies' do
    it 'returns a successful response' do
      get '/api/v1/companies', headers: headers
      expect(response).to have_http_status(:success)
    end
  end
end
