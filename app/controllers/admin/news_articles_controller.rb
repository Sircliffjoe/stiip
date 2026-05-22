class Admin::NewsArticlesController < Admin::ApplicationController
  before_action :set_article, only: [:show, :edit, :update, :destroy]

  def index
    @articles = NewsArticle.includes(:author, :companies).order(created_at: :desc)
  end

  def show
  end

  def new
    @article = NewsArticle.new(published_at: Time.current)
  end

  def create
    @article = NewsArticle.new(article_params)
    @article.author = current_user

    if @article.save
      sync_companies
      notify_watchlist_users(@article)
      redirect_to admin_news_article_path(@article), notice: "News article created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @article.update(article_params)
      sync_companies
      notify_watchlist_users(@article)
      redirect_to admin_news_article_path(@article), notice: "News article updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @article.destroy
    redirect_to admin_news_articles_path, notice: "News article deleted."
  end

  private

  def set_article
    @article = NewsArticle.find(params[:id])
  end

  def article_params
    params.require(:news_article).permit(:title, :slug, :summary, :source, :source_url, :published_at, :featured, :category)
  end

  def sync_companies
    company_ids = Array(params[:news_article][:company_ids]).reject(&:blank?)
    @article.company_ids = company_ids
  end

  def notify_watchlist_users(article)
    return unless article.published?

    users = User.joins(watchlists: :companies).where(companies: { id: article.company_ids }).distinct
    users.find_each do |user|
      Notification.find_or_create_by!(user: user, notifiable: article, notification_type: "news") do |notification|
        notification.title = "Watchlist news: #{article.title}"
        notification.body = article.summary
      end
    end
  end
end
