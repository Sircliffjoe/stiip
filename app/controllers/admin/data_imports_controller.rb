module Admin
  class DataImportsController < ApplicationController
    before_action :require_admin!
    
    # GET /admin/data-imports
    def index
      @recent_imports = DataImportLog.order(created_at: :desc).limit(50)
    end

    # POST /admin/data-imports/sync-prices
    def sync_prices
      date = params[:date].present? ? Date.parse(params[:date]) : Date.current
      provider = (params[:provider] || "mock").to_sym
      
      begin
        coordinator = DataIngestion::SyncCoordinator.new(provider: provider)
        result = coordinator.sync_stock_prices(date: date)
        
        log_import("Stock Prices", provider, result)
        
        if result[:success]
          redirect_to admin_data_imports_path, notice: "✅ Successfully synced #{result[:count]} stock prices"
        else
          redirect_to admin_data_imports_path, alert: "❌ Sync failed: #{result[:error]}"
        end
      rescue StandardError => e
        Rails.logger.error("Data import error: #{e.message}")
        redirect_to admin_data_imports_path, alert: "❌ Error: #{e.message}"
      end
    end

    # POST /admin/data-imports/sync-dividends
    def sync_dividends
      start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : 10.years.ago.to_date
      end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current
      provider = (params[:provider] || "eodhd").to_sym
      
      begin
        coordinator = DataIngestion::SyncCoordinator.new(provider: provider)
        result = coordinator.sync_dividends(start_date: start_date, end_date: end_date)
        
        log_import("Dividends", provider, result)
        
        if result[:success]
          redirect_to admin_data_imports_path, notice: "✅ Successfully synced #{result[:count]} dividends"
        else
          redirect_to admin_data_imports_path, alert: "❌ Sync failed: #{result[:error]}"
        end
      rescue StandardError => e
        Rails.logger.error("Dividend import error: #{e.message}")
        redirect_to admin_data_imports_path, alert: "❌ Error: #{e.message}"
      end
    end

    # POST /admin/data-imports/sync-news
    def sync_news
      limit = (params[:limit] || 50).to_i
      provider = (params[:provider] || "mock").to_sym
      
      begin
        coordinator = DataIngestion::SyncCoordinator.new(provider: provider)
        result = coordinator.sync_news(limit: limit)
        
        log_import("News", provider, result)
        
        if result[:success]
          redirect_to admin_data_imports_path, notice: "✅ Successfully synced #{result[:count]} news articles"
        else
          redirect_to admin_data_imports_path, alert: "❌ Sync failed: #{result[:error]}"
        end
      rescue StandardError => e
        Rails.logger.error("News import error: #{e.message}")
        redirect_to admin_data_imports_path, alert: "❌ Error: #{e.message}"
      end
    end

    # POST /admin/data-imports/import-csv
    def import_csv
      file = params[:csv_file]
      
      raise ArgumentError, "No file selected" unless file
      raise ArgumentError, "File must be CSV" unless file.content_type == "text/csv"
      
      # Save temporarily
      temp_path = "#{Rails.root}/tmp/uploads/#{SecureRandom.hex(8)}.csv"
      FileUtils.mkdir_p(File.dirname(temp_path))
      File.write(temp_path, file.read)
      
      begin
        provider = DataIngestion::Providers::CsvProvider.new(file_path: temp_path)
        coordinator = DataIngestion::SyncCoordinator.new(provider: provider)
        result = coordinator.sync_stock_prices(date: Date.current)
        
        log_import("CSV Import", "csv", result)
        
        if result[:success]
          redirect_to admin_data_imports_path, notice: "✅ Successfully imported #{result[:count]} records from CSV"
        else
          redirect_to admin_data_imports_path, alert: "❌ Import failed: #{result[:error]}"
        end
      rescue StandardError => e
        Rails.logger.error("CSV import error: #{e.message}")
        redirect_to admin_data_imports_path, alert: "❌ Error: #{e.message}"
      ensure
        File.delete(temp_path) if File.exist?(temp_path)
      end
    end

    private

    def log_import(data_type, provider, result)
      DataImportLog.create!(
        data_type: data_type,
        provider: provider.to_s,
        status: result[:success] ? "success" : "failed",
        records_imported: result[:count] || 0,
        error_message: result[:error],
        imported_by: current_user
      )
    end
  end
end
