# Phase 2: Stock Data Ingestion Architecture - Implementation Guide

## Overview

Phase 2 implements a **provider-based data ingestion system** that allows importing stock prices, dividends, and news from multiple sources (CSV, APIs, NGX). The system includes:

- **4 Provider implementations** (Mock, CSV, NGX, API)
- **Data Normalizer** for validation and consistency
- **Sync Coordinator** for orchestrating ingestion
- **Admin UI** for managing imports
- **Rake tasks** for command-line imports

## Architecture

```
User/Script
    ↓
┌─────────────────────────────────┐
│   SyncCoordinator               │
│   (Orchestrates all syncs)      │
└─────────────────────────────────┘
    ↓              ↓              ↓
Provider      Normalizer      Persistence
├─ Mock        ├─ Validate    └─ Database
├─ CSV         ├─ Normalize      (Transactions)
├─ NGX         └─ Transform
└─ API
```

## Components

### 1. Providers (`app/services/data_ingestion/providers/`)

Each provider implements the `BaseProvider` interface with methods:
- `fetch_end_of_day_prices(date:)` 
- `fetch_dividends(start_date:, end_date:)`
- `fetch_news(limit:)`

#### MockProvider
- **Purpose**: Testing and development without external APIs
- **Usage**: Default provider for development
- **Output**: Realistic mock data for all Nigerian companies

#### CsvProvider  
- **Purpose**: Bulk import from CSV files
- **CSV Format**: `ticker_symbol, date, open, high, low, close, volume`
- **Example**:
  ```
  GTCO,2026-05-20,45.50,46.25,45.00,45.80,2500000
  UBA,2026-05-20,21.40,21.85,21.00,21.60,3200000
  ```
- **Supports**: Stock prices, dividends, news (CSV with appropriate columns)

#### NgxProvider
- **Purpose**: Real-time data from Nigerian Stock Exchange
- **Status**: Placeholder (requires NGX API credentials/endpoints)
- **TODO**: Implement when NGX API documentation available

#### ApiProvider
- **Purpose**: Generic REST API integration
- **Supports**: Alpha Vantage, Finnhub, or custom APIs
- **Configuration**:
  ```ruby
  STOCK_API_KEY=your_key
  STOCK_API_BASE_URL=https://api.example.com
  ```

### 2. DataNormalizer (`app/services/data_ingestion/data_normalizer.rb`)

Validates and normalizes data from any source before database persistence.

**Features**:
- ✅ Ticker validation (1-10 chars, alphanumeric)
- ✅ Price consistency checks (High ≥ Low, High ≥ Close, etc.)
- ✅ Date range validation (not future, after 2000)
- ✅ Volume and dividend validation
- ✅ Detailed error messages
- ✅ URL, title, and content validation for news

**Example Usage**:
```ruby
normalizer = DataIngestion::DataNormalizer.new
normalized = normalizer.normalize_price(
  ticker_symbol: "GTCO",
  date: Date.today,
  open: 45.50,
  high: 46.25,
  low: 45.00,
  close: 45.80,
  volume: 2500000
)
# Raises DataNormalizer::ValidationError if invalid
```

### 3. SyncCoordinator (`app/services/data_ingestion/sync_coordinator.rb`)

Orchestrates all ingestion operations with transaction management.

**Public Methods**:
- `sync_stock_prices(date:, rollback_on_error:)` - Sync prices for specific date
- `sync_dividends(start_date:, end_date:, rollback_on_error:)` - Sync dividends
- `sync_news(limit:, rollback_on_error:)` - Sync news articles
- `sync_all(date:, rollback_on_error:)` - Complete sync

**Example Usage**:
```ruby
coordinator = DataIngestion::SyncCoordinator.new(provider: :mock)
result = coordinator.sync_stock_prices(date: Date.today)

# Result: { success: true, count: 15, date: #<Date: 2026-05-22> }
```

## Usage Methods

### Method 1: Rake Tasks (Command Line)

#### Sync Stock Prices
```bash
# Default (mock provider, today's date)
rails data_ingestion:sync_prices

# Specific date
rails data_ingestion:sync_prices[mock,2026-05-20]
```

#### Import from CSV
```bash
rails data_ingestion:import_csv[/path/to/prices.csv]
```

Example CSV at: `tmp/sample_prices.csv`

#### Full Data Sync
```bash
rails data_ingestion:sync_all[mock]
```

#### Test Ingestion
```bash
rails data_ingestion:test:mock
```

### Method 2: Rails Console

```ruby
# Open Rails console
rails console

# Option A: Using Coordinator
coordinator = DataIngestion::SyncCoordinator.new(provider: :mock)
result = coordinator.sync_stock_prices

# Option B: Using Fetch service directly
fetcher = DataIngestion::FetchStockPrices.new(provider: DataIngestion::Providers::MockProvider.new)
count = fetcher.call

# Option C: CSV Import
provider = DataIngestion::Providers::CsvProvider.new(file_path: "tmp/sample_prices.csv")
coordinator = DataIngestion::SyncCoordinator.new(provider: provider)
result = coordinator.sync_stock_prices
```

### Method 3: Admin UI

Navigate to `/admin/data-imports`:
1. Click "Sync Stock Prices" to import today's data
2. Upload CSV file for bulk import
3. View import history and statistics

### Method 4: Background Jobs (Phase 2b)

```ruby
# Coming soon - scheduled jobs with Sidekiq
SyncStockPricesJob.perform_later
SyncDividendsJob.perform_later
SyncMarketNewsJob.perform_later
```

## CSV Import Guide

### Creating a Price CSV

**Required columns**: `ticker_symbol, date, open, high, low, close, volume`

**Sample**:
```csv
ticker_symbol,date,open,high,low,close,volume
GTCO,2026-05-20,45.50,46.25,45.00,45.80,2500000
ZENITHBANK,2026-05-20,28.30,28.75,27.95,28.50,1800000
```

**Minimal format** (auto-fill OHLC):
```csv
ticker_symbol,date,close,volume
GTCO,2026-05-20,45.80,2500000
```

### Import Steps

1. **Create CSV** with price data
2. **Run import**:
   ```bash
   rails data_ingestion:import_csv[tmp/sample_prices.csv]
   ```
3. **Verify** in database:
   ```ruby
   rails console
   StockPrice.where(date: Date.parse("2026-05-20")).count
   ```

## Configuration

### Environment Variables

```bash
# For API Provider
STOCK_API_KEY=your_api_key
STOCK_API_BASE_URL=https://api.example.com

# For NGX Provider (when implemented)
NGX_API_KEY=your_ngx_key
NGX_API_BASE_URL=https://api.ngxgroup.com
```

### Error Handling

All methods include automatic transaction rollback on errors:

```ruby
result = coordinator.sync_stock_prices(rollback_on_error: true)
# => { success: false, error: "validation error message", rollback: true }
```

### Logging

All operations log to `log/development.log`:

```
[DataIngestion::SyncCoordinator] Starting stock price sync for 2026-05-22
[SyncCoordinator] Price validation error for GTCO: Price seems unreasonable
[SyncCoordinator] Successfully synced 14 stock prices
```

## Data Models

### StockPrice
```ruby
belongs_to :company
validates :date, uniqueness: { scope: :company_id }
# Fields: date, open, high, low, close, volume
```

### Dividend
```ruby
belongs_to :company
validates :qualification_date, :amount
# Fields: amount, qualification_date, payment_date, year, status
```

### CompanyNews (NewsArticle)
```ruby
has_many :companies, through: :news_company_links
# Fields: title, content, source, url, published_at
```

### DataImportLog
```ruby
belongs_to :imported_by, class_name: "User"
# Tracks all imports for audit trail
# Fields: data_type, provider, status, records_imported, error_message
```

## Testing the Integration

### Quick Test (Rails Console)

```ruby
# 1. Test mock provider
coordinator = DataIngestion::SyncCoordinator.new(provider: :mock)
result = coordinator.sync_stock_prices
puts "Synced: #{result[:count]} prices" if result[:success]

# 2. Verify database
companies = Company.limit(3)
companies.each do |c|
  latest = c.stock_prices.latest.first
  puts "#{c.ticker_symbol}: #{latest.close} (#{latest.date})"
end

# 3. Test CSV import
provider = DataIngestion::Providers::CsvProvider.new(file_path: "tmp/sample_prices.csv")
coord = DataIngestion::SyncCoordinator.new(provider: provider)
result = coord.sync_stock_prices
puts "CSV import: #{result[:count]} records"

# 4. Check import logs
DataImportLog.recent.limit(5).each { |log| puts "#{log.data_type}: #{log.status}" }
```

### Rake Task Test

```bash
# Test with mock provider
rails data_ingestion:test:mock

# Output:
# 📊 Testing stock price sync...
#    Result: ✅ 15 prices
# 💰 Testing dividend sync...
#    Result: ✅ 5 dividends
# 📰 Testing news sync...
#    Result: ✅ 20 articles
# ✅ All tests completed!
```

## Advanced Usage

### Custom Provider

```ruby
class MyCustomProvider < DataIngestion::Providers::BaseProvider
  def fetch_end_of_day_prices(date: Date.current)
    # Your implementation
  end

  def fetch_dividends(start_date:, end_date:)
    # Your implementation
  end

  def fetch_news(limit: 20)
    # Your implementation
  end
end

# Use it
coordinator = DataIngestion::SyncCoordinator.new(provider: MyCustomProvider.new)
```

### Batch Processing

```ruby
# Sync last 30 days
30.times do |i|
  date = (i + 1).days.ago
  coordinator = DataIngestion::SyncCoordinator.new(provider: :csv)
  result = coordinator.sync_stock_prices(date: date)
  puts "#{date}: #{result[:count]} prices"
end
```

## Troubleshooting

### Issue: "File not found"
```ruby
# Ensure file exists and path is correct
File.exist?("tmp/sample_prices.csv") # => true
```

### Issue: Validation errors
```ruby
# Check error message
result = coordinator.sync_stock_prices
puts result[:error] if !result[:success]
```

### Issue: CSV columns not recognized
```ruby
# Ensure exact column names (case-sensitive):
# ticker_symbol, date, open, high, low, close, volume
```

### Issue: Duplicate prices
```ruby
# StockPrice has uniqueness on (company_id, date)
# Use find_or_initialize_by to update existing records
```

## Performance

- **Mock provider**: ~50ms per company
- **CSV import**: Depends on file size (15 companies/companies = ~100ms)
- **Database transactions**: Automatic rollback if any record fails
- **Batch size**: Limited by transaction size (recommend <10,000 records)

## Next Steps

- **Phase 2b**: Implement Sidekiq background jobs
- **Phase 3**: Dividend ranking and watchlist alerts
- **Phase 4**: Admin dashboard with import analytics
- **Phase 5**: NGX and real API providers

## Security

- ✅ SQL injection safe (using parameterized queries)
- ✅ File upload validation in admin controller
- ✅ Admin-only access to import functions
- ✅ Input validation for all CSV data
- ✅ Audit logging of all imports
- ⚠️ TODO: Rate limiting for API providers
- ⚠️ TODO: API key rotation for OAuth providers

## Support

For issues or questions:
1. Check `log/development.log` for detailed error messages
2. Run `rails data_ingestion:test:mock` to verify system
3. Review CSV format against sample in `tmp/sample_prices.csv`
4. Ensure all companies exist: `Company.pluck(:ticker_symbol).inspect`
