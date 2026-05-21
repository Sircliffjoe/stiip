class NewsArticle < ApplicationRecord
  belongs_to :author, class_name: 'User', optional: true
  has_many :company_news, dependent: :destroy
  has_many :companies, through: :company_news
  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, on: :create

  private

  def generate_slug
    self.slug = title.parameterize if title.present? && slug.blank?
  end
end
