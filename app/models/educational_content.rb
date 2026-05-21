class EducationalContent < ApplicationRecord
  belongs_to :author, class_name: 'User', optional: true
  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings

  enum :difficulty_level, { beginner: 0, intermediate: 1, advanced: 2 }

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, on: :create

  private

  def generate_slug
    self.slug = title.parameterize if title.present? && slug.blank?
  end
end
