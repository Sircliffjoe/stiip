require 'fileutils'

directories = [
  'app/controllers/api/v1',
  'app/serializers',
  'app/services/subscriptions'
]
directories.each { |dir| FileUtils.mkdir_p(dir) }

files = {}

# Serializers
files['app/serializers/company_serializer.rb'] = <<~RUBY
  class CompanySerializer
    include JSONAPI::Serializer
    attributes :name, :ticker_symbol, :market_cap, :pe_ratio, :dividend_yield
    
    attribute :current_price do |object|
      object.latest_price
    end

    attribute :beginner_explanation do |object|
      object.pe_ratio_explanation
    end
  end
RUBY

files['app/serializers/stock_price_serializer.rb'] = <<~RUBY
  class StockPriceSerializer
    include JSONAPI::Serializer
    attributes :date, :open, :high, :low, :close, :volume
  end
RUBY

# API Controllers
files['app/controllers/api/v1/base_controller.rb'] = <<~RUBY
  module Api
    module V1
      class BaseController < ApplicationController
        skip_before_action :verify_authenticity_token
        before_action :authenticate_api_user!

        private

        def authenticate_api_user!
          token = request.headers['Authorization']&.split(' ')&.last
          # In a real app, you'd verify JWT or secure API token here
          # For MVP, we stub it to allow local testing
          unless token == 'test_token'
            render json: { error: 'Unauthorized' }, status: :unauthorized
          end
        end
      end
    end
  end
RUBY

files['app/controllers/api/v1/companies_controller.rb'] = <<~RUBY
  module Api
    module V1
      class CompaniesController < BaseController
        def index
          companies = Company.all
          render json: CompanySerializer.new(companies).serializable_hash
        end

        def show
          company = Company.find_by!(ticker_symbol: params[:id])
          render json: CompanySerializer.new(company).serializable_hash
        end
      end
    end
  end
RUBY

files['app/controllers/api/v1/prices_controller.rb'] = <<~RUBY
  module Api
    module V1
      class PricesController < BaseController
        def index
          company = Company.find_by!(ticker_symbol: params[:company_id])
          prices = company.stock_prices.order(date: :desc).limit(30)
          render json: StockPriceSerializer.new(prices).serializable_hash
        end
      end
    end
  end
RUBY

# Subscription Webhooks & Services
files['app/controllers/webhooks/subscriptions_controller.rb'] = <<~RUBY
  module Webhooks
    class SubscriptionsController < ApplicationController
      skip_before_action :verify_authenticity_token

      def create
        # Paystack/Flutterwave webhook handling
        event = params[:event]
        data = params[:data]

        case event
        when 'charge.success'
          Subscriptions::ProcessPayment.new(data).call
        when 'subscription.disable'
          Subscriptions::Cancel.new(data).call
        end

        head :ok
      rescue StandardError => e
        Rails.logger.error("Webhook processing failed: \#{e.message}")
        head :unprocessable_entity
      end
    end
  end
RUBY

files['app/services/subscriptions/process_payment.rb'] = <<~RUBY
  module Subscriptions
    class ProcessPayment
      def initialize(payload)
        @payload = payload
      end

      def call
        email = @payload.dig('customer', 'email')
        user = User.find_by(email: email)
        return unless user

        subscription = user.subscription || user.build_subscription
        subscription.update!(
          status: :active,
          plan: :premium,
          expires_at: 1.month.from_now
        )
        
        user.premium!
        
        # Notify user
        Notifications::Create.new(
          user: user,
          title: "Payment Successful",
          message: "You are now a Premium subscriber!",
          type: "success"
        ).call
      end
    end
  end
RUBY

# Update Routes
files['config/routes.rb'] = <<~RUBY
  Rails.application.routes.draw do
    get "up" => "rails/health#show", as: :rails_health_check

    devise_for :users

    resources :companies, param: :ticker_symbol, only: [:index, :show]
    resources :dividends, only: [:index]
    resources :news_articles, param: :slug, only: [:index, :show], path: 'news'
    resources :educational_contents, param: :slug, only: [:index, :show], path: 'learn'
    resources :watchlists
    resources :notifications, only: [:index]
    
    namespace :admin do
      get 'dashboard', to: 'dashboard#index'
      resources :users
      resources :companies
      resources :stock_prices do
        collection do
          post :import
        end
      end
      resources :dividends
    end
    
    namespace :api do
      namespace :v1 do
        resources :companies, only: [:index, :show] do
          resources :prices, only: [:index]
        end
      end
    end
    
    namespace :webhooks do
      post 'subscriptions', to: 'subscriptions#create'
    end

    get '/profile', to: 'profiles#edit'
    get '/search', to: 'search#index'
    get '/market', to: 'market#index'
    get '/dashboard', to: 'dashboard#index'

    root "pages#home"
  end
RUBY

files.each do |filename, content|
  File.write(filename, content)
  puts "Created #{filename}"
end
