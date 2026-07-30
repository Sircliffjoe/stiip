class EducationalContent < ApplicationRecord
  include PgSearch::Model
  multisearchable against: [:title, :body, :excerpt],
                  if: :published?
  pg_search_scope :search_by_term, against: [:title, :body, :excerpt],
                  using: { tsearch: { prefix: true, dictionary: "english" } }
  belongs_to :author, class_name: 'User', optional: true
  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings
  has_one_attached :image

  enum :difficulty_level, { beginner: 0, intermediate: 1, advanced: 2 }

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug

  scope :published, -> { where.not(published_at: nil).where("published_at <= ?", Time.current) }
  scope :featured, -> { where(featured: true) }

  def published?
    published_at.present? && published_at <= Time.current
  end

  private

  def generate_slug
    return if title.blank?
    
    # Always generate slug from title if blank
    if slug.blank?
      self.slug = title.parameterize
    end
    
    # Ensure uniqueness by adding a suffix if needed
    if slug.present? && EducationalContent.where(slug: slug).where.not(id: id).exists?
      self.slug = "#{title.parameterize}-#{SecureRandom.hex(4)}"
    end
  end
end
