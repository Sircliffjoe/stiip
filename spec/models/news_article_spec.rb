require "rails_helper"

RSpec.describe NewsArticle, type: :model do
  it "generates a unique slug when another article has the same title" do
    described_class.create!(
      title: "Nigeria inflation cools as equities rally",
      summary: "First article",
      source: "EODHD",
      source_url: "https://example.com/first",
      published_at: Time.current
    )

    article = described_class.create!(
      title: "Nigeria inflation cools as equities rally",
      summary: "Second article",
      source: "EODHD",
      source_url: "https://example.com/second",
      published_at: Time.current
    )

    expect(article.slug).to eq("nigeria-inflation-cools-as-equities-rally-2")
  end
end
