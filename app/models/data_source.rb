class DataSource < ApplicationRecord
  validates :name, presence: true
  validates :provider_type, presence: true
end
