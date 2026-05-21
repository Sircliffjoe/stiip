class NewsArticlesController < ApplicationController
  def index
    @articles = NewsArticle.all.order(published_at: :desc)
  end
  def show
    @article = NewsArticle.find_by!(slug: params[:slug])
  end
end
