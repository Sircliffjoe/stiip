require 'rails_helper'

RSpec.describe "Api::V1::News", type: :request do
  let!(:article) { NewsArticle.create!(title: "Breaking Financial News", slug: "breaking-financial-news", summary: "Market rises", source: "Nairametrics", published_at: Time.current) }
  let(:headers) { { 'Authorization' => 'Bearer test_token' } }

  describe "GET /api/v1/news" do
    it "returns all published news" do
      get api_v1_news_index_path, headers: headers
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first["title"]).to eq("Breaking Financial News")
    end
  end

  describe "GET /api/v1/news/:id" do
    it "returns a specific article" do
      get api_v1_news_path(id: article.slug), headers: headers
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["title"]).to eq("Breaking Financial News")
    end
  end
end
