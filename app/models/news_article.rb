class NewsArticle < ApplicationRecord
  include PgSearch::Model
  multisearchable against: [:title, :summary],
                  if: :published?
  pg_search_scope :search_by_term, against: [:title, :summary],
                  using: { tsearch: { prefix: true, dictionary: "english" } }
  belongs_to :author, class_name: 'User', optional: true
  has_many :company_news, dependent: :destroy
  has_many :companies, through: :company_news
  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings
  has_one_attached :image

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, if: -> { title.present? && slug.blank? }

  scope :published, -> { where.not(published_at: nil).where("published_at <= ?", Time.current) }
  scope :featured, -> { where(featured: true) }

  def to_param
    slug
  end

  def published?
    published_at.present? && published_at <= Time.current
  end

  private

  def generate_slug
    base_slug = title.parameterize.presence || SecureRandom.hex(8)
    candidate = base_slug
    suffix = 2

    while self.class.where(slug: candidate).where.not(id: id).exists?
      candidate = "#{base_slug}-#{suffix}"
      suffix += 1
    end

    self.slug = candidate
  end
end
