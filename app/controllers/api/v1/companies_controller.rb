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
