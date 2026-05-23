module Api
  module V1
    class DividendsController < BaseController
      def index
        if params[:company_id]
          company = Company.find_by!(ticker_symbol: params[:company_id])
          dividends = company.dividends.order(qualification_date: :desc).limit(30)
        else
          dividends = Dividend.order(qualification_date: :desc).limit(50)
        end
        render json: dividends.as_json(include: :company)
      end
    end
  end
end
