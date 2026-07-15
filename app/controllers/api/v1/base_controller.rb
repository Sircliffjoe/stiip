module Api
  module V1
    class BaseController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :authenticate_api_user!
      before_action :enforce_api_quota!
      after_action :record_api_request!

      attr_reader :current_api_key

      private

      def authenticate_api_user!
        token = request.headers['Authorization']&.split(' ')&.last
        @current_api_key = ApiKey.authenticate(token)

        return if @current_api_key&.user&.then { |user| AccessPolicy.new(user).can_use_api? }

        render json: { error: "Unauthorized. A valid Business/API key is required." }, status: :unauthorized
      end

      def enforce_api_quota!
        return if performed?

        if current_api_key.monthly_quota_exceeded?
          render json: { error: "Monthly API quota exceeded." }, status: :too_many_requests
        end
      end

      def record_api_request!
        current_api_key&.record_request! unless response.status >= 400
      end
    end
  end
end
