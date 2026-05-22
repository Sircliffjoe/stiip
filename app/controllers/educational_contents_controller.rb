class EducationalContentsController < ApplicationController
  def index
    @featured_content = EducationalContent.published.featured.order(published_at: :desc).first
    @contents = EducationalContent.published.includes(:tags).order(published_at: :desc)
    @categories = @contents.map(&:category).compact.uniq.sort
  end

  def show
    @content = EducationalContent.published.find_by!(slug: params[:slug])
    @related_contents = EducationalContent.published.where(category: @content.category).where.not(id: @content.id).order(published_at: :desc).limit(3)
  end
end
