require 'fileutils'
require 'time'

migrations_dir = 'db/migrate'
FileUtils.mkdir_p(migrations_dir)

migrations = [
  { name: 'enable_uuid_extension',
    content: <<~RUBY
      class EnableUuidExtension < ActiveRecord::Migration[8.1]
        def change
          enable_extension 'pgcrypto'
        end
      end
    RUBY
  },
  { name: 'devise_create_users',
    content: <<~RUBY
      class DeviseCreateUsers < ActiveRecord::Migration[8.1]
        def change
          create_table :users, id: :uuid do |t|
            ## Database authenticatable
            t.string :email,              null: false, default: ""
            t.string :encrypted_password, null: false, default: ""

            ## Recoverable
            t.string   :reset_password_token
            t.datetime :reset_password_sent_at

            ## Rememberable
            t.datetime :remember_created_at

            ## Trackable
            t.integer  :sign_in_count, default: 0, null: false
            t.datetime :current_sign_in_at
            t.datetime :last_sign_in_at
            t.string   :current_sign_in_ip
            t.string   :last_sign_in_ip

            ## Confirmable
            t.string   :confirmation_token
            t.datetime :confirmed_at
            t.datetime :confirmation_sent_at
            t.string   :unconfirmed_email

            t.integer :role, default: 0, null: false
            t.string :first_name
            t.string :last_name
            t.string :phone

            t.timestamps null: false
          end

          add_index :users, :email,                unique: true
          add_index :users, :reset_password_token, unique: true
          add_index :users, :confirmation_token,   unique: true
        end
      end
    RUBY
  },
  { name: 'create_sectors',
    content: <<~RUBY
      class CreateSectors < ActiveRecord::Migration[8.1]
        def change
          create_table :sectors, id: :uuid do |t|
            t.string :name, null: false
            t.string :slug, null: false
            t.text :description
            t.string :icon

            t.timestamps
          end
          add_index :sectors, :slug, unique: true
          add_index :sectors, :name, unique: true
        end
      end
    RUBY
  },
  { name: 'create_companies',
    content: <<~RUBY
      class CreateCompanies < ActiveRecord::Migration[8.1]
        def change
          create_table :companies, id: :uuid do |t|
            t.string :name, null: false
            t.string :ticker_symbol, null: false
            t.references :sector, null: false, foreign_key: true, type: :uuid
            t.text :description
            t.decimal :market_cap, precision: 20, scale: 2
            t.decimal :pe_ratio, precision: 10, scale: 2
            t.decimal :current_price, precision: 15, scale: 2
            t.decimal :opening_price, precision: 15, scale: 2
            t.decimal :closing_price, precision: 15, scale: 2
            t.decimal :high_52_week, precision: 15, scale: 2
            t.decimal :low_52_week, precision: 15, scale: 2
            t.decimal :dividend_yield, precision: 8, scale: 2
            t.bigint :shares_outstanding
            t.string :website
            t.string :investor_relations_url
            t.integer :founded_year
            t.boolean :listed, default: true

            t.timestamps
          end
          add_index :companies, :ticker_symbol, unique: true
          add_index :companies, :name
        end
      end
    RUBY
  },
  { name: 'create_stock_prices',
    content: <<~RUBY
      class CreateStockPrices < ActiveRecord::Migration[8.1]
        def change
          create_table :stock_prices, id: :uuid do |t|
            t.references :company, null: false, foreign_key: true, type: :uuid
            t.date :date, null: false
            t.decimal :open, precision: 15, scale: 2
            t.decimal :close, precision: 15, scale: 2
            t.decimal :high, precision: 15, scale: 2
            t.decimal :low, precision: 15, scale: 2
            t.bigint :volume
            t.decimal :change_percent, precision: 8, scale: 2

            t.timestamps
          end
          add_index :stock_prices, [:company_id, :date], unique: true
        end
      end
    RUBY
  },
  { name: 'create_dividends',
    content: <<~RUBY
      class CreateDividends < ActiveRecord::Migration[8.1]
        def change
          create_table :dividends, id: :uuid do |t|
            t.references :company, null: false, foreign_key: true, type: :uuid
            t.decimal :amount, precision: 15, scale: 2, null: false
            t.string :currency, default: "NGN", null: false
            t.date :qualification_date
            t.date :payment_date
            t.integer :year, null: false
            t.boolean :interim, default: false
            t.integer :status, default: 0, null: false

            t.timestamps
          end
          add_index :dividends, [:company_id, :year, :interim], unique: true
        end
      end
    RUBY
  },
  { name: 'create_watchlists',
    content: <<~RUBY
      class CreateWatchlists < ActiveRecord::Migration[8.1]
        def change
          create_table :watchlists, id: :uuid do |t|
            t.references :user, null: false, foreign_key: true, type: :uuid
            t.string :name, null: false
            t.boolean :is_default, default: false

            t.timestamps
          end
        end
      end
    RUBY
  },
  { name: 'create_watchlist_items',
    content: <<~RUBY
      class CreateWatchlistItems < ActiveRecord::Migration[8.1]
        def change
          create_table :watchlist_items, id: :uuid do |t|
            t.references :watchlist, null: false, foreign_key: true, type: :uuid
            t.references :company, null: false, foreign_key: true, type: :uuid

            t.timestamps
          end
          add_index :watchlist_items, [:watchlist_id, :company_id], unique: true
        end
      end
    RUBY
  },
  { name: 'create_notifications',
    content: <<~RUBY
      class CreateNotifications < ActiveRecord::Migration[8.1]
        def change
          create_table :notifications, id: :uuid do |t|
            t.references :user, null: false, foreign_key: true, type: :uuid
            t.string :title, null: false
            t.text :body
            t.string :notification_type
            t.datetime :read_at
            t.references :notifiable, polymorphic: true, type: :uuid

            t.timestamps
          end
        end
      end
    RUBY
  },
  { name: 'create_news_articles',
    content: <<~RUBY
      class CreateNewsArticles < ActiveRecord::Migration[8.1]
        def change
          create_table :news_articles, id: :uuid do |t|
            t.string :title, null: false
            t.string :slug, null: false
            t.text :summary
            t.string :source
            t.string :source_url
            t.datetime :published_at
            t.boolean :featured, default: false
            t.string :category
            t.references :author, foreign_key: { to_table: :users }, type: :uuid

            t.timestamps
          end
          add_index :news_articles, :slug, unique: true
        end
      end
    RUBY
  },
  { name: 'create_company_news',
    content: <<~RUBY
      class CreateCompanyNews < ActiveRecord::Migration[8.1]
        def change
          create_table :company_news, id: :uuid do |t|
            t.references :company, null: false, foreign_key: true, type: :uuid
            t.references :news_article, null: false, foreign_key: true, type: :uuid

            t.timestamps
          end
          add_index :company_news, [:company_id, :news_article_id], unique: true
        end
      end
    RUBY
  },
  { name: 'create_educational_contents',
    content: <<~RUBY
      class CreateEducationalContents < ActiveRecord::Migration[8.1]
        def change
          create_table :educational_contents, id: :uuid do |t|
            t.string :title, null: false
            t.string :slug, null: false
            t.text :summary
            t.string :category
            t.integer :difficulty_level, default: 0
            t.boolean :featured, default: false
            t.references :author, foreign_key: { to_table: :users }, type: :uuid
            t.datetime :published_at

            t.timestamps
          end
          add_index :educational_contents, :slug, unique: true
        end
      end
    RUBY
  },
  { name: 'create_subscriptions',
    content: <<~RUBY
      class CreateSubscriptions < ActiveRecord::Migration[8.1]
        def change
          create_table :subscriptions, id: :uuid do |t|
            t.references :user, null: false, foreign_key: true, type: :uuid
            t.integer :plan, default: 0, null: false
            t.integer :status, default: 0, null: false
            t.datetime :starts_at
            t.datetime :expires_at
            t.string :payment_reference

            t.timestamps
          end
        end
      end
    RUBY
  },
  { name: 'create_market_events',
    content: <<~RUBY
      class CreateMarketEvents < ActiveRecord::Migration[8.1]
        def change
          create_table :market_events, id: :uuid do |t|
            t.string :title, null: false
            t.text :description
            t.integer :event_type, default: 0, null: false
            t.datetime :event_date, null: false
            t.references :company, foreign_key: true, type: :uuid

            t.timestamps
          end
        end
      end
    RUBY
  },
  { name: 'create_audit_logs',
    content: <<~RUBY
      class CreateAuditLogs < ActiveRecord::Migration[8.1]
        def change
          create_table :audit_logs, id: :uuid do |t|
            t.references :user, foreign_key: true, type: :uuid
            t.string :action, null: false
            t.references :auditable, polymorphic: true, type: :uuid
            t.jsonb :metadata, default: {}
            t.string :ip_address

            t.timestamps
          end
        end
      end
    RUBY
  },
  { name: 'create_data_sources',
    content: <<~RUBY
      class CreateDataSources < ActiveRecord::Migration[8.1]
        def change
          create_table :data_sources, id: :uuid do |t|
            t.string :name, null: false
            t.string :provider_type, null: false
            t.jsonb :config, default: {}
            t.boolean :active, default: true
            t.datetime :last_synced_at

            t.timestamps
          end
        end
      end
    RUBY
  },
  { name: 'create_tags',
    content: <<~RUBY
      class CreateTags < ActiveRecord::Migration[8.1]
        def change
          create_table :tags, id: :uuid do |t|
            t.string :name, null: false

            t.timestamps
          end
          add_index :tags, :name, unique: true

          create_table :taggings, id: :uuid do |t|
            t.references :tag, null: false, foreign_key: true, type: :uuid
            t.references :taggable, polymorphic: true, null: false, type: :uuid

            t.timestamps
          end
          add_index :taggings, [:tag_id, :taggable_type, :taggable_id], unique: true, name: 'index_taggings_uniqueness'
        end
      end
    RUBY
  }
]

# Generate timestamped files
time = Time.now.utc
migrations.each_with_index do |m, idx|
  timestamp = (time + idx).strftime("%Y%m%d%H%M%S")
  filename = "#{migrations_dir}/#{timestamp}_#{m[:name]}.rb"
  File.write(filename, m[:content])
  puts "Created #{filename}"
end
