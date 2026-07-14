module DataIngestion
  class SyncCoordinator
    # Orchestrates all data ingestion operations
    # Handles provider selection, error recovery, transaction management
    
    class SyncError < StandardError; end

    def initialize(provider: :mock)
      @provider = select_provider(provider)
      @normalizer = DataNormalizer.new
    end

    # ============================================
    # Public API
    # ============================================

    def sync_stock_prices(date: Date.current, rollback_on_error: true, ensure_companies: true)
      Rails.logger.info("[SyncCoordinator] Starting stock price sync for #{date}")
      
      begin
        raise SyncError, "Stock price date cannot be in the future" if date.to_date > Date.current
        sync_companies(rollback_on_error: rollback_on_error) if ensure_companies && @provider.respond_to?(:fetch_companies)

        raw_data = fetch_prices(date)
        normalized_data = normalize_prices(raw_data)
        persisted_count = persist_prices(normalized_data)
        
        Rails.logger.info("[SyncCoordinator] Successfully synced #{persisted_count} stock prices")
        { success: true, count: persisted_count, date: date }
      rescue StandardError => e
        handle_sync_error(e, "stock_prices", rollback_on_error)
      end
    end

    def sync_companies(rollback_on_error: true)
      Rails.logger.info("[SyncCoordinator] Starting company sync")

      begin
        raise SyncError, "Provider does not support company sync" unless @provider.respond_to?(:fetch_companies)

        raw_data = @provider.fetch_companies
        persisted_count = persist_companies(raw_data)

        Rails.logger.info("[SyncCoordinator] Successfully synced #{persisted_count} companies")
        { success: true, count: persisted_count }
      rescue StandardError => e
        handle_sync_error(e, "companies", rollback_on_error)
      end
    end

    def sync_company_price(ticker_symbol, date: Date.current, rollback_on_error: true)
      Rails.logger.info("[SyncCoordinator] Starting stock price sync for #{ticker_symbol}")

      begin
        raise SyncError, "Stock price date cannot be in the future" if date.to_date > Date.current

        raw_data = if @provider.respond_to?(:fetch_stock_price)
                     [@provider.fetch_stock_price(ticker_symbol, date: date)].compact
                   else
                     fetch_prices(date).select { |row| row[:ticker_symbol].to_s.casecmp?(ticker_symbol.to_s) }
                   end

        normalized_data = normalize_prices(raw_data)
        persisted_count = persist_prices(normalized_data)

        Rails.logger.info("[SyncCoordinator] Successfully synced #{persisted_count} stock price for #{ticker_symbol}")
        { success: true, count: persisted_count, date: date }
      rescue StandardError => e
        handle_sync_error(e, "stock_price", rollback_on_error)
      end
    end

    def sync_dividends(start_date: 10.years.ago.to_date, end_date: Date.current, rollback_on_error: true)
      Rails.logger.info("[SyncCoordinator] Starting dividend sync from #{start_date} to #{end_date}")
      
      begin
        raw_data = fetch_dividends(start_date, end_date)
        normalized_data = normalize_dividends(raw_data)
        persisted_count = persist_dividends(normalized_data)
        
        Rails.logger.info("[SyncCoordinator] Successfully synced #{persisted_count} dividends")
        { success: true, count: persisted_count, date_range: "#{start_date} to #{end_date}" }
      rescue StandardError => e
        handle_sync_error(e, "dividends", rollback_on_error)
      end
    end

    def sync_news(limit: 50, rollback_on_error: true)
      Rails.logger.info("[SyncCoordinator] Starting news sync (limit: #{limit})")
      
      begin
        raw_data = fetch_news(limit)
        normalized_data = normalize_news(raw_data)
        persisted_count = persist_news(normalized_data)
        
        Rails.logger.info("[SyncCoordinator] Successfully synced #{persisted_count} news articles")
        { success: true, count: persisted_count, limit: limit }
      rescue StandardError => e
        handle_sync_error(e, "news", rollback_on_error)
      end
    end

    def sync_all(date: Date.current, rollback_on_error: true)
      Rails.logger.info("[SyncCoordinator] Starting full sync")
      companies_result = if @provider.respond_to?(:fetch_companies)
                           sync_companies(rollback_on_error: rollback_on_error)
                         else
                           { success: true, count: 0, skipped: true }
                         end
      
      results = {
        companies: companies_result,
        stock_prices: sync_stock_prices(date: date, rollback_on_error: rollback_on_error, ensure_companies: false),
        dividends: sync_dividends(rollback_on_error: rollback_on_error),
        news: sync_news(rollback_on_error: rollback_on_error)
      }
      
      summary = {
        success: results.values.all? { |r| r[:success] },
        timestamp: Time.current,
        results: results
      }
      
      Rails.logger.info("[SyncCoordinator] Full sync complete: #{summary.inspect}")
      summary
    end

    # ============================================
    # Private Methods
    # ============================================

    private

    def select_provider(provider_key)
      case provider_key
      when :mock
        Providers::MockProvider.new
      when :csv
        raise ArgumentError, "CSV provider requires file_path parameter"
      when :ngx
        Providers::NgxProvider.new
      when :ngn_market
        Providers::NgnMarketProvider.new
      when :eodhd
        Providers::EodhdProvider.new
      when :market, :composite
        Providers::CompositeMarketProvider.new
      when :api
        Providers::ApiProvider.new
      when Providers::BaseProvider
        provider_key
      else
        raise ArgumentError, "Unknown provider: #{provider_key}"
      end
    end

    def fetch_prices(date)
      @provider.fetch_end_of_day_prices(date: date)
    rescue StandardError => e
      raise SyncError, "Failed to fetch prices: #{e.message}"
    end

    def fetch_dividends(start_date, end_date)
      @provider.fetch_dividends(start_date: start_date, end_date: end_date)
    rescue StandardError => e
      raise SyncError, "Failed to fetch dividends: #{e.message}"
    end

    def fetch_news(limit)
      @provider.fetch_news(limit: limit)
    rescue StandardError => e
      raise SyncError, "Failed to fetch news: #{e.message}"
    end

    def normalize_prices(raw_data)
      raw_data.map do |row|
        @normalizer.normalize_price(row)
      rescue DataNormalizer::ValidationError => e
        Rails.logger.warn("[SyncCoordinator] Price validation error for #{row[:ticker_symbol]}: #{e.message}")
        nil
      end.compact
    end

    def normalize_dividends(raw_data)
      raw_data.map do |row|
        @normalizer.normalize_dividend(row)
      rescue DataNormalizer::ValidationError => e
        Rails.logger.warn("[SyncCoordinator] Dividend validation error for #{row[:ticker_symbol]}: #{e.message}")
        nil
      end.compact
    end

    def normalize_news(raw_data)
      raw_data.map do |row|
        @normalizer.normalize_news(row)
      rescue DataNormalizer::ValidationError => e
        Rails.logger.warn("[SyncCoordinator] News validation error for #{row[:title]}: #{e.message}")
        nil
      end.compact
    end

    def persist_prices(data)
      count = 0
      
      ActiveRecord::Base.transaction do
        data.each do |price_data|
          company = Company.find_by(ticker_symbol: price_data[:ticker_symbol])
          next unless company
          
          stock_price = StockPrice.find_or_initialize_by(
            company_id: company.id,
            date: price_data[:date]
          )
          
          stock_price.update!(
            open: price_data[:open],
            high: price_data[:high],
            low: price_data[:low],
            close: price_data[:close],
            volume: price_data[:volume],
            change_percent: price_data[:change_percent]
          )
          
          company.update!(company_price_attributes(price_data))
          
          count += 1
        end
      end
      
      count
    rescue StandardError => e
      raise SyncError, "Failed to persist prices: #{e.message}"
    end

    def persist_companies(data)
      count = 0

      ActiveRecord::Base.transaction do
        data.each do |company_data|
          ticker = company_data[:ticker_symbol].to_s.upcase.strip
          next if ticker.blank?

          sector = find_or_create_sector(company_data[:sector])
          company = Company.find_or_initialize_by(ticker_symbol: ticker)
          company.assign_attributes(company_attributes(company_data, sector))
          company.save!
          count += 1
        end
      end

      count
    rescue StandardError => e
      raise SyncError, "Failed to persist companies: #{e.message}"
    end

    def find_or_create_sector(name)
      normalized_name = normalize_sector_name(name)
      slug = normalized_name.parameterize
      sector = Sector.find_or_initialize_by(slug: slug)
      sector.name = normalized_name
      sector.save!
      sector
    end

    def normalize_sector_name(name)
      value = name.to_s.strip
      return "Unclassified" if value.blank?
      return "ICT" if value.casecmp?("ict")

      value == value.upcase ? value.titleize : value
    end

    def company_attributes(company_data, sector)
      {
        name: normalize_company_name(company_data[:name], company_data[:ticker_symbol]),
        sector: sector,
        website: company_data[:website],
        market_cap: company_data[:market_cap],
        current_price: company_data[:current_price],
        opening_price: company_data[:opening_price],
        closing_price: company_data[:closing_price],
        shares_outstanding: company_data[:shares_outstanding],
        high_52_week: company_data[:high_52_week],
        low_52_week: company_data[:low_52_week],
        listed: company_data.fetch(:listed, true)
      }.compact
    end

    def normalize_company_name(name, ticker_symbol)
      value = name.to_s.strip
      return ticker_symbol.to_s.upcase if value.blank?
      return value unless value == value.upcase

      value.titleize
        .gsub(/\bPlc\b/, "PLC")
        .gsub(/\bMtn\b/, "MTN")
        .gsub(/\bFbn\b/, "FBN")
        .gsub(/\bUba\b/, "UBA")
        .gsub(/\bGtcoplc\b/, "GTCO PLC")
    end

    def company_price_attributes(price_data)
      {
        current_price: price_data[:close],
        opening_price: price_data[:open],
        closing_price: price_data[:close],
        market_cap: price_data[:market_cap],
        shares_outstanding: price_data[:shares_outstanding],
        pe_ratio: price_data[:pe_ratio],
        high_52_week: price_data[:high_52_week],
        low_52_week: price_data[:low_52_week]
      }.compact
    end

    def persist_dividends(data)
      count = 0
      
      ActiveRecord::Base.transaction do
        data.each do |div_data|
          company = Company.find_by(ticker_symbol: div_data[:ticker_symbol])
          next unless company
          
          Dividend.upsert({
            company_id: company.id,
            year: div_data[:year],
            interim: div_data[:interim] || false,
            qualification_date: div_data[:qualification_date],
            amount: div_data[:amount],
            currency: div_data[:currency] || "NGN",
            payment_date: div_data[:payment_date],
            status: :announced,
            created_at: Time.current,
            updated_at: Time.current
          }, unique_by: [:company_id, :year, :interim], on_duplicate: :update)
          
          count += 1
        end
      end
      
      count
    rescue StandardError => e
      raise SyncError, "Failed to persist dividends: #{e.message}"
    end

    def persist_news(data)
      count = 0
      
      ActiveRecord::Base.transaction do
        data.each do |news_data|
          article = if news_data[:url].present?
                      NewsArticle.find_or_initialize_by(source_url: news_data[:url])
                    else
                      NewsArticle.find_or_initialize_by(title: news_data[:title])
                    end
          
          article.update!(
            title: news_data[:title],
            summary: news_data[:content],
            source: news_data[:source],
            source_url: news_data[:url],
            category: "Market",
            published_at: news_data[:published_at]
          )
          
          # Link to related companies if tickers are provided
          if news_data[:related_tickers].any?
            news_data[:related_tickers].each do |ticker|
              company = Company.find_by(ticker_symbol: ticker)
              CompanyNews.find_or_create_by!(news_article: article, company: company) if company
            end
          end
          
          count += 1
        end
      end
      
      count
    rescue StandardError => e
      raise SyncError, "Failed to persist news: #{e.message}"
    end

    def handle_sync_error(error, operation, rollback_on_error)
      error_message = "#{operation} sync failed: #{error.message}"
      Rails.logger.error("[SyncCoordinator] #{error_message}")
      
      {
        success: false,
        operation: operation,
        error: error_message,
        rollback: rollback_on_error
      }
    end
  end
end
