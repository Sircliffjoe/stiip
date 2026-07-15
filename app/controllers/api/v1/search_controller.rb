module Api
  module V1
    class SearchController < BaseController
      def index
        query = params[:query]
        return render json: { error: 'Query parameter is required' }, status: :bad_request unless query.present?

        companies = Company.search_by_term(query).limit(10)
        news = NewsArticle.published.search_by_term(query).limit(10)

        render json: {
          companies: companies.as_json(only: [:id, :name, :ticker_symbol, :logo_url]),
          news: news.as_json(only: [:id, :title, :slug, :published_at])
        }
      end
    end
  end
end
