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
