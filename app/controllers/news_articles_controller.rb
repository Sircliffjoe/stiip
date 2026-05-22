class NewsArticlesController < ApplicationController
  def index
    @featured_article = NewsArticle.published.featured.order(published_at: :desc).first
    @articles = NewsArticle.published.includes(:companies, :tags).order(published_at: :desc)
    @categories = @articles.map(&:category).compact.uniq.sort
  end

  def show
    @article = NewsArticle.published.find_by!(slug: params[:slug])
    @related_articles = NewsArticle.published.where(category: @article.category).where.not(id: @article.id).order(published_at: :desc).limit(3)
  end
end
