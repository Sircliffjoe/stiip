class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable, :trackable

  enum :role, { free: 0, premium: 1, analyst: 2, admin: 3 }, suffix: true

  has_many :watchlists, dependent: :destroy
  has_many :watchlist_items, through: :watchlists
  has_many :notifications, dependent: :destroy
  has_one :subscription, dependent: :destroy
  has_many :authored_articles, class_name: 'NewsArticle', foreign_key: 'author_id'
  has_many :authored_educational_contents, class_name: 'EducationalContent', foreign_key: 'author_id'
  has_many :audit_logs

  validates :first_name, :last_name, presence: true

  def full_name
    "#{first_name} #{last_name}"
  end
end
