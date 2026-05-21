require 'fileutils'

models_dir = 'app/models'
FileUtils.mkdir_p(models_dir)

models = {
  'user.rb' => <<~RUBY,
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
        "\#{first_name} \#{last_name}"
      end
    end
  RUBY

  'sector.rb' => <<~RUBY,
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
  RUBY

  'company.rb' => <<~RUBY,
    class Company < ApplicationRecord
      belongs_to :sector
      has_many :stock_prices, dependent: :destroy
      has_many :dividends, dependent: :destroy
      has_many :watchlist_items, dependent: :destroy
      has_many :company_news, dependent: :destroy
      has_many :news_articles, through: :company_news
      has_many :market_events, dependent: :destroy

      validates :name, presence: true
      validates :ticker_symbol, presence: true, uniqueness: true

      def latest_price
        current_price || stock_prices.order(date: :desc).first&.close
      end

      def pe_ratio_explanation
        return "No data available." unless pe_ratio
        
        if pe_ratio < 10
          "This stock might be undervalued compared to its earnings. (PE: \#{pe_ratio})"
        elsif pe_ratio > 25
          "This stock is priced high relative to its earnings, meaning investors expect high growth. (PE: \#{pe_ratio})"
        else
          "This stock is reasonably priced relative to its earnings. (PE: \#{pe_ratio})"
        end
      end
    end
  RUBY

  'stock_price.rb' => <<~RUBY,
    class StockPrice < ApplicationRecord
      belongs_to :company

      validates :date, presence: true
      validates :date, uniqueness: { scope: :company_id, message: "Price already recorded for this date" }
    end
  RUBY

  'dividend.rb' => <<~RUBY,
    class Dividend < ApplicationRecord
      belongs_to :company

      enum :status, { announced: 0, paid: 1, cancelled: 2 }

      validates :amount, presence: true, numericality: { greater_than: 0 }
      validates :year, presence: true
    end
  RUBY

  'watchlist.rb' => <<~RUBY,
    class Watchlist < ApplicationRecord
      belongs_to :user
      has_many :watchlist_items, dependent: :destroy
      has_many :companies, through: :watchlist_items

      validates :name, presence: true
    end
  RUBY

  'watchlist_item.rb' => <<~RUBY,
    class WatchlistItem < ApplicationRecord
      belongs_to :watchlist
      belongs_to :company

      validates :company_id, uniqueness: { scope: :watchlist_id, message: "Company already in watchlist" }
    end
  RUBY

  'notification.rb' => <<~RUBY,
    class Notification < ApplicationRecord
      belongs_to :user
      belongs_to :notifiable, polymorphic: true, optional: true

      validates :title, presence: true

      scope :unread, -> { where(read_at: nil) }
      scope :read, -> { where.not(read_at: nil) }

      def mark_as_read!
        update(read_at: Time.current)
      end
    end
  RUBY

  'news_article.rb' => <<~RUBY,
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
  RUBY

  'company_news.rb' => <<~RUBY,
    class CompanyNews < ApplicationRecord
      belongs_to :company
      belongs_to :news_article

      validates :company_id, uniqueness: { scope: :news_article_id }
    end
  RUBY

  'educational_content.rb' => <<~RUBY,
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
  RUBY

  'subscription.rb' => <<~RUBY,
    class Subscription < ApplicationRecord
      belongs_to :user

      enum :plan, { free: 0, premium: 1 }
      enum :status, { pending: 0, active: 1, cancelled: 2, expired: 3 }

      validates :plan, presence: true
      validates :status, presence: true
    end
  RUBY

  'market_event.rb' => <<~RUBY,
    class MarketEvent < ApplicationRecord
      belongs_to :company, optional: true

      enum :event_type, { general_news: 0, earnings_report: 1, dividend_announcement: 2, agm: 3 }

      validates :title, presence: true
      validates :event_date, presence: true
    end
  RUBY

  'audit_log.rb' => <<~RUBY,
    class AuditLog < ApplicationRecord
      belongs_to :user, optional: true
      belongs_to :auditable, polymorphic: true, optional: true

      validates :action, presence: true
    end
  RUBY

  'data_source.rb' => <<~RUBY,
    class DataSource < ApplicationRecord
      validates :name, presence: true
      validates :provider_type, presence: true
    end
  RUBY

  'tag.rb' => <<~RUBY,
    class Tag < ApplicationRecord
      has_many :taggings, dependent: :destroy
      
      validates :name, presence: true, uniqueness: true
    end
  RUBY

  'tagging.rb' => <<~RUBY
    class Tagging < ApplicationRecord
      belongs_to :tag
      belongs_to :taggable, polymorphic: true

      validates :tag_id, uniqueness: { scope: [:taggable_type, :taggable_id] }
    end
  RUBY
}

models.each do |filename, content|
  path = File.join(models_dir, filename)
  File.write(path, content)
  puts "Created \#{path}"
end
