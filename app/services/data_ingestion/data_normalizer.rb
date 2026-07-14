module DataIngestion
  class DataNormalizer
    require "cgi"

    # Validates and normalizes data from any provider before database persistence
    # Ensures consistency, handles missing values, and applies business logic
    
    class ValidationError < StandardError; end

    # ============================================
    # Stock Price Normalization
    # ============================================
    
    def self.normalize_price(data)
      new.normalize_price(data)
    end

    def normalize_price(data)
      close = validate_price(data[:close])
      {
        ticker_symbol: validate_ticker(data[:ticker_symbol]),
        date: validate_date(data[:date]),
        open: validate_price(data[:open]) || close,
        high: validate_price(data[:high]) || close,
        low: validate_price(data[:low]) || close,
        close: close,
        volume: validate_volume(data[:volume]),
        change_percent: validate_decimal(data[:change_percent]),
        market_cap: validate_decimal(data[:market_cap]),
        shares_outstanding: validate_volume(data[:shares_outstanding]),
        pe_ratio: validate_decimal(data[:pe_ratio]),
        high_52_week: validate_price(data[:high_52_week]),
        low_52_week: validate_price(data[:low_52_week])
      }.tap { |normalized| validate_price_consistency(normalized) }
    end

    # ============================================
    # Dividend Normalization
    # ============================================
    
    def self.normalize_dividend(data)
      new.normalize_dividend(data)
    end

    def normalize_dividend(data)
      {
        ticker_symbol: validate_ticker(data[:ticker_symbol]),
        amount: validate_dividend_amount(data[:amount]),
        qualification_date: validate_date(data[:qualification_date]),
        payment_date: validate_date(data[:payment_date]),
        year: validate_year(data[:year]),
        interim: ActiveModel::Type::Boolean.new.cast(data[:interim]),
        currency: validate_currency(data[:currency])
      }
    end

    # ============================================
    # News Normalization
    # ============================================
    
    def self.normalize_news(data)
      new.normalize_news(data)
    end

    def normalize_news(data)
      {
        title: validate_title(data[:title]),
        content: validate_content(data[:content]),
        source: validate_source(data[:source]),
        url: validate_url(data[:url]),
        published_at: validate_datetime(data[:published_at]),
        related_tickers: validate_tickers_array(data[:related_tickers])
      }
    end

    private

    # ============================================
    # Validators
    # ============================================

    def validate_ticker(value)
      raise ValidationError, "Ticker is required" if value.blank?
      ticker = value.to_s.upcase.strip
      raise ValidationError, "Ticker must be 1-10 characters" unless (1..10).include?(ticker.length)
      raise ValidationError, "Ticker must contain only alphanumeric characters" unless ticker.match?(/\A[A-Z0-9]+\z/)
      ticker
    end

    def validate_date(value)
      return nil if value.blank?
      
      date = case value
             when Date
               value
             when String
               Date.parse(value)
             when Integer
               Date.strptime(value.to_s, "%s")
             else
               value.to_date
             end
      
      # Validate date is not in the future (or within reasonable range)
      raise ValidationError, "Date cannot be more than 1 year in the future" if date > 1.year.from_now
      raise ValidationError, "Date cannot be before year 2000" if date.year < 2000
      
      date
    rescue StandardError => e
      raise ValidationError, "Invalid date: #{e.message}"
    end

    def validate_datetime(value)
      return Time.current if value.blank?
      
      datetime = case value
                 when Time
                   value
                 when String
                   Time.parse(value)
                 when Integer
                   Time.at(value)
                 else
                   value.to_time
                 end
      
      # Validate datetime is not in future
      raise ValidationError, "DateTime cannot be in the future" if datetime > Time.current + 1.hour
      
      datetime
    rescue StandardError => e
      raise ValidationError, "Invalid datetime: #{e.message}"
    end

    def validate_price(value)
      return nil if value.blank?
      
      price = Float(value.to_s)
      raise ValidationError, "Price must be positive" unless price.positive?
      raise ValidationError, "Price seems unreasonable (> 1,000,000)" if price > 1_000_000
      
      price.round(2)
    rescue ArgumentError, TypeError
      raise ValidationError, "Invalid price format: #{value}"
    end

    def validate_dividend_amount(value)
      return nil if value.blank?
      
      amount = Float(value.to_s)
      raise ValidationError, "Dividend must be non-negative" unless amount >= 0
      raise ValidationError, "Dividend seems unreasonable (> 100,000)" if amount > 100_000
      
      amount.round(4)
    rescue ArgumentError, TypeError
      raise ValidationError, "Invalid dividend amount: #{value}"
    end

    def validate_volume(value)
      return nil if value.blank?
      
      volume = Integer(value.to_s)
      raise ValidationError, "Volume must be non-negative" unless volume >= 0
      
      volume
    rescue StandardError
      raise ValidationError, "Invalid volume: #{value}"
    end

    def validate_decimal(value)
      return nil if value.blank?

      BigDecimal(value.to_s).round(2)
    rescue ArgumentError, TypeError
      raise ValidationError, "Invalid decimal: #{value}"
    end

    def validate_year(value)
      return Date.today.year if value.blank?
      
      year = Integer(value.to_s)
      raise ValidationError, "Year must be between 1900 and next year" unless (1900..Date.today.year + 1).include?(year)
      
      year
    rescue StandardError
      raise ValidationError, "Invalid year: #{value}"
    end

    def validate_currency(value)
      currency = value.to_s.strip.upcase.presence || "NGN"
      raise ValidationError, "Currency must be a 3-letter code" unless currency.match?(/\A[A-Z]{3}\z/)
      currency
    end

    def validate_title(value)
      raise ValidationError, "Title is required" if value.blank?
      title = value.to_s.strip
      raise ValidationError, "Title must be less than 500 characters" if title.length > 500
      title
    end

    def validate_content(value)
      content = clean_text(value)
      raise ValidationError, "Content must be less than 50,000 characters" if content.length > 50_000
      content
    end

    def validate_source(value)
      source = clean_text(value).presence || "Unknown"
      source[0...100] # Limit to 100 chars
    end

    def clean_text(value)
      decoded = CGI.unescapeHTML(value.to_s)
      without_tags = decoded.gsub(/<[^>]*>/, " ")
      without_tags
        .gsub(/\u00a0/, " ")
        .gsub(/[[:space:]]+/, " ")
        .strip
    end

    def validate_url(value)
      return nil if value.blank?
      
      url = value.to_s.strip
      raise ValidationError, "Invalid URL format" unless url.match?(%r{\Ahttps?://})
      raise ValidationError, "URL must be less than 500 characters" if url.length > 500
      
      url
    end

    def validate_tickers_array(value)
      return [] if value.blank?
      
      tickers = case value
                when Array
                  value
                when String
                  value.split(",").map(&:strip)
                else
                  [value.to_s]
                end
      
      tickers.map { |t| validate_ticker(t) }.compact.uniq
    rescue StandardError
      []
    end

    # ============================================
    # Business Logic Validation
    # ============================================

    def validate_price_consistency(data)
      return if data[:high].nil? || data[:low].nil?
      
      # High should be >= Low
      if data[:high] < data[:low]
        raise ValidationError, "High price (#{data[:high]}) cannot be less than Low (#{data[:low]})"
      end

      # High should be >= Close and Open
      if data[:high].present? && data[:close].present?
        if data[:high] < data[:close]
          raise ValidationError, "High price cannot be less than Close"
        end
      end

      # Low should be <= Close and Open
      if data[:low].present? && data[:close].present?
        if data[:low] > data[:close]
          raise ValidationError, "Low price cannot be greater than Close"
        end
      end

      # If open and close differ significantly, check they're within high/low
      if data[:open].present? && data[:close].present?
        min_price = [data[:open], data[:close]].min
        max_price = [data[:open], data[:close]].max
        
        if data[:high].present? && data[:high] < max_price
          raise ValidationError, "High price must be >= both Open and Close"
        end
        
        if data[:low].present? && data[:low] > min_price
          raise ValidationError, "Low price must be <= both Open and Close"
        end
      end

      data
    end
  end
end
