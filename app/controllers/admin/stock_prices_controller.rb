class Admin::StockPricesController < Admin::ApplicationController
  def index
    @recent_prices = StockPrice.includes(:company).order(date: :desc).limit(50)
  end
  
  def import
    file = params[:file]
    
    if file.nil?
      redirect_to admin_stock_prices_path, alert: "No file selected"
      return
    end

    if file.content_type != "text/csv" && !file.original_filename.end_with?('.csv')
      redirect_to admin_stock_prices_path, alert: "File must be CSV"
      return
    end

    temp_path = "#{Rails.root}/tmp/uploads/#{SecureRandom.hex(8)}.csv"
    FileUtils.mkdir_p(File.dirname(temp_path))
    File.write(temp_path, file.read)
    
    begin
      provider = DataIngestion::Providers::CsvProvider.new(file_path: temp_path)
      coordinator = DataIngestion::SyncCoordinator.new(provider: provider)
      result = coordinator.sync_stock_prices(date: Date.current)
      
      if result[:success]
        redirect_to admin_stock_prices_path, notice: "Successfully imported #{result[:count]} stock prices from CSV"
      else
        redirect_to admin_stock_prices_path, alert: "Import failed: #{result[:error]}"
      end
    rescue StandardError => e
      Rails.logger.error("CSV import error: #{e.message}")
      redirect_to admin_stock_prices_path, alert: "Error: #{e.message}"
    ensure
      File.delete(temp_path) if File.exist?(temp_path)
    end
  end
end
