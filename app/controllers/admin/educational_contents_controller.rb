class Admin::EducationalContentsController < Admin::ApplicationController
  before_action :set_content, only: [:show, :edit, :update, :destroy]

  def index
    @contents = EducationalContent.includes(:author).order(created_at: :desc)
  end

  def show
  end

  def new
    @content = EducationalContent.new(published_at: Time.current)
  end

  def create
    @content = EducationalContent.new(content_params)
    @content.author = current_user
    @content.published_at ||= Time.current

    if @content.save
      redirect_to admin_educational_content_path(@content), notice: "Educational content created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @content.update(content_params)
      redirect_to admin_educational_content_path(@content), notice: "Educational content updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @content.destroy
    redirect_to admin_educational_contents_path, notice: "Educational content deleted."
  end

  private

  def set_content
    @content = EducationalContent.find(params[:id])
  end

  def content_params
    params.require(:educational_content).permit(:title, :summary, :body, :excerpt, :category, :difficulty_level, :featured, :published_at)
  end
end
