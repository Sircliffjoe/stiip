class SearchController < ApplicationController
  def index
    @query = params[:query]
    return unless @query.present?

    @login_required = !user_signed_in?
    limit = premium_user? ? 10 : 3

    @companies = @login_required ? Company.none : Company.search_by_term(@query).limit(limit)
    @news = @login_required ? NewsArticle.none : NewsArticle.published.search_by_term(@query).limit(limit)
    @educational = @login_required ? EducationalContent.none : EducationalContent.published.search_by_term(@query).limit(limit)

    @total_count = @companies.length + @news.length + @educational.length
  end
end
