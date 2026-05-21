class Sector < ApplicationRecord
  has_many :companies

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, on: :create

  private

  def generate_slug
    self.slug = name.parameterize if name.present? && slug.blank?
  end
end
