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
