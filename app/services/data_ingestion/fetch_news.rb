module DataIngestion
  class FetchNews
    def initialize(provider: Providers::MockProvider.new)
      @provider = provider
    end

    def call(limit: 20)
      raw_data = @provider.fetch_news(limit: limit)
      
      ActiveRecord::Base.transaction do
        raw_data.each do |data|
          article = NewsArticle.find_or_initialize_by(url: data[:url])
          next if article.persisted? # Skip if we already have it

          article.title = data[:title]
          article.content = data[:content]
          article.source = data[:source]
          article.published_at = data[:published_at]
          article.save!

          # Link to companies if tickers were provided
          data[:related_tickers].each do |ticker|
            company = Company.find_by(ticker_symbol: ticker)
            CompanyNews.create!(company: company, news_article: article) if company
          end
        end
      end
    end
  end
end
