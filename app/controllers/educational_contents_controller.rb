class EducationalContentsController < ApplicationController
  def index
    @contents = EducationalContent.all.order(published_at: :desc)
  end
  def show
    @content = EducationalContent.find_by!(slug: params[:slug])
  end
end
