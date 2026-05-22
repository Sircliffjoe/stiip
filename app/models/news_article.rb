class NewsArticle < ApplicationRecord
  belongs_to :author, class_name: 'User', optional: true
  has_many :company_news, dependent: :destroy
  has_many :companies, through: :company_news
  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, on: :create

  scope :published, -> { where.not(published_at: nil).where("published_at <= ?", Time.current) }
  scope :featured, -> { where(featured: true) }

  def published?
    published_at.present? && published_at <= Time.current
  end

  private

  def generate_slug
    self.slug = title.parameterize if title.present? && slug.blank?
  end
end
