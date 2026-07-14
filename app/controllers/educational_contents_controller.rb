class EducationalContentsController < ApplicationController
  def index
    @featured_content = EducationalContent.published.featured.order(published_at: :desc).first
    @contents = EducationalContent.published.includes(:tags).order(published_at: :desc)
    @categories = @contents.map(&:category).compact.uniq.sort
  end

  def show
    # Try to find by slug first
    @content = EducationalContent.find_by(slug: params[:slug])
    
    # If not found by slug, try by ID (for backwards compatibility or if slug is nil)
    @content ||= EducationalContent.find_by(id: params[:slug]) if params[:slug].match?(/^[0-9a-f-]+$/)
    
    raise ActiveRecord::RecordNotFound, "Educational content not found" unless @content
    
    # Allow viewing unpublished content if the current user is the author or an admin
    unless @content.published? || (user_signed_in? && (@content.author == current_user || current_user.admin?))
      raise ActiveRecord::RecordNotFound
    end
    
    @related_contents = EducationalContent.published.where(category: @content.category).where.not(id: @content.id).order(published_at: :desc).limit(3)
  end
end
