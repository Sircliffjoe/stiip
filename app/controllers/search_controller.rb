class SearchController < ApplicationController
  def index
    @query = params[:query]
    return unless @query.present?

    @companies = Company.search_by_term(@query).limit(10)
    @news = NewsArticle.published.search_by_term(@query).limit(10)
    @educational = EducationalContent.published.search_by_term(@query).limit(10)

    @total_count = @companies.length + @news.length + @educational.length
  end
end
