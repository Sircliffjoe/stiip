module Api
  module V1
    class NewsController < BaseController
      def index
        news = NewsArticle.published.order(published_at: :desc).limit(20)
        render json: news.as_json(except: [:body])
      end

      def show
        article = NewsArticle.published.find_by!(slug: params[:id])
        render json: article.as_json
      end
    end
  end
end
