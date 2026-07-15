class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable, :trackable

  enum :role, { free: 0, premium: 1, analyst: 2, admin: 3, business_api: 4 }, suffix: true

  has_many :watchlists, dependent: :destroy
  has_many :watchlist_items, through: :watchlists
  has_many :notifications, dependent: :destroy
  has_one :subscription, dependent: :destroy
  has_many :api_keys, dependent: :destroy
  has_many :authored_articles, class_name: 'NewsArticle', foreign_key: 'author_id'
  has_many :authored_educational_contents, class_name: 'EducationalContent', foreign_key: 'author_id'
  has_many :audit_logs

  after_create :ensure_free_subscription!

  validates :first_name, :last_name, presence: true

  def full_name
    "#{first_name} #{last_name}"
  end

  def premium?
    premium_role? || business_api_role? || analyst_role? || admin_role?
  end

  def business_api?
    business_api_role? || admin_role?
  end

  def ensure_free_subscription!
    return if subscription.present?

    plan = business_api_role? ? :business_api : (premium? ? :premium : :free)

    create_subscription!(
      plan: plan,
      status: :active,
      starts_at: Time.current
    )
  end
end
