require 'rails_helper'

RSpec.describe "Admin::NewsArticles", type: :request do
  let(:admin_user) do
    User.create!(
      email: "admin-news@example.com",
      password: "password",
      first_name: "Admin",
      last_name: "User",
      confirmed_at: Time.current,
      role: :admin
    )
  end

  let!(:article) do
    NewsArticle.create!(
      title: "Sample news",
      summary: "This is a sample summary",
      source: "WaffiHub",
      published_at: Time.current,
      author: admin_user
    )
  end

  before do
    sign_in admin_user
  end

  describe "GET /admin/news/:id" do
    it "finds article by slug" do
      get "/admin/news/#{article.slug}"
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Sample news")
    end

    it "finds article by id" do
      get "/admin/news/#{article.id}"
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Sample news")
    end
  end
end
