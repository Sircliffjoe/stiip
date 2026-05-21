module DataIngestion
  module Providers
    class BaseProvider
      class APIError < StandardError; end

      def fetch_end_of_day_prices(date: Date.current)
        raise NotImplementedError, "Subclasses must implement fetch_end_of_day_prices"
      end

      def fetch_dividends(start_date:, end_date:)
        raise NotImplementedError, "Subclasses must implement fetch_dividends"
      end

      def fetch_news(limit: 20)
        raise NotImplementedError, "Subclasses must implement fetch_news"
      end
      
      protected
      
      def handle_request
        yield
      rescue StandardError => e
        Rails.logger.error("[#{self.class.name}] API Error: #{e.message}")
        raise APIError, e.message
      end
    end
  end
end
