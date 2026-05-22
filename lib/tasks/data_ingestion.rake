namespace :data_ingestion do
  desc "Sync stock prices from provider (default: mock)"
  task :sync_prices, [:provider, :date] => :environment do |t, args|
    provider = (args[:provider] || "mock").to_sym
    date = args[:date] ? Date.parse(args[:date]) : Date.current
    
    coordinator = DataIngestion::SyncCoordinator.new(provider: provider)
    result = coordinator.sync_stock_prices(date: date)
    
    if result[:success]
      puts "✅ Successfully synced #{result[:count]} stock prices for #{date}"
    else
      puts "❌ Sync failed: #{result[:error]}"
      exit 1
    end
  end

  desc "Sync dividends from provider (default: mock)"
  task :sync_dividends, [:provider, :start_date, :end_date] => :environment do |t, args|
    provider = (args[:provider] || "mock").to_sym
    start_date = args[:start_date] ? Date.parse(args[:start_date]) : Date.current
    end_date = args[:end_date] ? Date.parse(args[:end_date]) : 1.month.from_now
    
    coordinator = DataIngestion::SyncCoordinator.new(provider: provider)
    result = coordinator.sync_dividends(start_date: start_date, end_date: end_date)
    
    if result[:success]
      puts "✅ Successfully synced #{result[:count]} dividends"
    else
      puts "❌ Sync failed: #{result[:error]}"
      exit 1
    end
  end

  desc "Sync news from provider (default: mock)"
  task :sync_news, [:provider, :limit] => :environment do |t, args|
    provider = (args[:provider] || "mock").to_sym
    limit = (args[:limit] || 50).to_i
    
    coordinator = DataIngestion::SyncCoordinator.new(provider: provider)
    result = coordinator.sync_news(limit: limit)
    
    if result[:success]
      puts "✅ Successfully synced #{result[:count]} news articles"
    else
      puts "❌ Sync failed: #{result[:error]}"
      exit 1
    end
  end

  desc "Full data sync (prices, dividends, news)"
  task :sync_all, [:provider] => :environment do |t, args|
    provider = (args[:provider] || "mock").to_sym
    
    coordinator = DataIngestion::SyncCoordinator.new(provider: provider)
    result = coordinator.sync_all
    
    puts "\n========== FULL DATA SYNC RESULTS =========="
    puts "Timestamp: #{result[:timestamp]}"
    puts "Status: #{result[:success] ? '✅ SUCCESS' : '❌ FAILED'}\n"
    
    result[:results].each do |type, res|
      if res[:success]
        puts "✅ #{type.to_s.humanize}: #{res[:count]} records"
      else
        puts "❌ #{type.to_s.humanize}: #{res[:error]}"
      end
    end
    
    exit 1 unless result[:success]
  end

  desc "Import stock prices from CSV file"
  task :import_csv, [:file_path, :date_column] => :environment do |t, args|
    file_path = args[:file_path]
    
    raise "Usage: rake data_ingestion:import_csv['/path/to/file.csv']" unless file_path
    raise "File not found: #{file_path}" unless File.exist?(file_path)
    
    puts "Importing CSV: #{file_path}"
    
    begin
      provider = DataIngestion::Providers::CsvProvider.new(file_path: file_path)
      coordinator = DataIngestion::SyncCoordinator.new(provider: provider)
      result = coordinator.sync_stock_prices(date: Date.current)
      
      if result[:success]
        puts "✅ Successfully imported #{result[:count]} records from CSV"
      else
        puts "❌ Import failed: #{result[:error]}"
        exit 1
      end
    rescue StandardError => e
      puts "❌ Error: #{e.message}"
      exit 1
    end
  end

  namespace :test do
    desc "Test data ingestion with mock provider"
    task :mock => :environment do
      puts "Testing data ingestion with mock provider...\n"
      
      coordinator = DataIngestion::SyncCoordinator.new(provider: :mock)
      
      # Test stock prices
      puts "📊 Testing stock price sync..."
      price_result = coordinator.sync_stock_prices
      puts "   Result: #{price_result[:success] ? '✅' : '❌'} #{price_result[:count]} prices"
      
      # Test dividends
      puts "💰 Testing dividend sync..."
      div_result = coordinator.sync_dividends
      puts "   Result: #{div_result[:success] ? '✅' : '❌'} #{div_result[:count]} dividends"
      
      # Test news
      puts "📰 Testing news sync..."
      news_result = coordinator.sync_news
      puts "   Result: #{news_result[:success] ? '✅' : '❌'} #{news_result[:count]} articles"
      
      puts "\n✅ All tests completed!"
    end
  end
end
