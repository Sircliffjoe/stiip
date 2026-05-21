class CompanyNews < ApplicationRecord
  belongs_to :company
  belongs_to :news_article

  validates :company_id, uniqueness: { scope: :news_article_id }
end
