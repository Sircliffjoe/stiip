# frozen_string_literal: true

puts "🌱 Seeding STIIP database..."

# ── Sectors ──────────────────────────────────────────────────────────────────
sectors = {
  "Financial Services" => "Banking, insurance, fintech, and capital markets",
  "Oil & Gas" => "Upstream, downstream, and midstream energy companies",
  "Consumer Goods" => "Food, beverages, personal care, and household products",
  "Industrial Goods" => "Cement, building materials, and infrastructure",
  "Healthcare" => "Pharmaceuticals, hospitals, and health services",
  "ICT" => "Telecommunications, software, and technology services",
  "Agriculture" => "Farming, agro-processing, and plantation companies",
  "Conglomerates" => "Multi-industry holding companies"
}

created_sectors = {}
sectors.each do |name, description|
  sector = Sector.find_or_create_by!(name: name) do |s|
    s.description = description if s.respond_to?(:description=)
  end
  created_sectors[name] = sector
  puts "  ✅ Sector: #{name}"
end

# ── Companies ────────────────────────────────────────────────────────────────
companies_data = [
  # Financial Services
  { name: "Guaranty Trust Holding Company", ticker_symbol: "GTCO", sector: "Financial Services",
    description: "One of Nigeria's largest financial institutions, providing banking, insurance, and asset management services across Africa.",
    current_price: 45.50, opening_price: 44.80, closing_price: 45.50, market_cap: 1_336_000_000_000,
    pe_ratio: 4.8, dividend_yield: 8.2, high_52_week: 52.00, low_52_week: 28.50,
    shares_outstanding: 29_370_000_000, founded_year: 1990, listed: true,
    website: "https://www.gtcoplc.com" },

  { name: "Zenith Bank", ticker_symbol: "ZENITHBANK", sector: "Financial Services",
    description: "A leading Nigerian bank known for its strong retail and commercial banking operations.",
    current_price: 38.90, opening_price: 38.20, closing_price: 38.90, market_cap: 1_221_000_000_000,
    pe_ratio: 3.5, dividend_yield: 9.0, high_52_week: 43.00, low_52_week: 22.50,
    shares_outstanding: 31_396_000_000, founded_year: 1990, listed: true,
    website: "https://www.zenithbank.com" },

  { name: "United Bank for Africa", ticker_symbol: "UBA", sector: "Financial Services",
    description: "Pan-African bank with operations in 20 African countries and presence in New York, London, and Paris.",
    current_price: 26.40, opening_price: 25.80, closing_price: 26.40, market_cap: 903_000_000_000,
    pe_ratio: 3.2, dividend_yield: 7.5, high_52_week: 30.00, low_52_week: 15.00,
    shares_outstanding: 34_200_000_000, founded_year: 1949, listed: true,
    website: "https://www.ubagroup.com" },

  { name: "Access Holdings", ticker_symbol: "ACCESSCORP", sector: "Financial Services",
    description: "Diversified financial services group with banking, insurance, and digital payment subsidiaries.",
    current_price: 22.15, opening_price: 21.80, closing_price: 22.15, market_cap: 786_000_000_000,
    pe_ratio: 4.1, dividend_yield: 6.8, high_52_week: 27.00, low_52_week: 12.50,
    shares_outstanding: 35_500_000_000, founded_year: 1989, listed: true,
    website: "https://www.accessholdings.com" },

  { name: "FBN Holdings", ticker_symbol: "FBNH", sector: "Financial Services",
    description: "Nigeria's oldest banking group, parent of First Bank of Nigeria and other financial services subsidiaries.",
    current_price: 28.30, opening_price: 27.50, closing_price: 28.30, market_cap: 1_014_000_000_000,
    pe_ratio: 5.2, dividend_yield: 5.3, high_52_week: 33.00, low_52_week: 14.00,
    shares_outstanding: 35_900_000_000, founded_year: 1894, listed: true,
    website: "https://www.fbnholdings.com" },

  # Oil & Gas
  { name: "Seplat Energy", ticker_symbol: "SEPLAT", sector: "Oil & Gas",
    description: "Leading Nigerian independent energy company focused on oil and gas exploration and production in the Niger Delta.",
    current_price: 3200.00, opening_price: 3150.00, closing_price: 3200.00, market_cap: 1_884_000_000_000,
    pe_ratio: 8.5, dividend_yield: 3.1, high_52_week: 3800.00, low_52_week: 2200.00,
    shares_outstanding: 588_600_000, founded_year: 2009, listed: true,
    website: "https://www.seplatenergy.com" },

  { name: "TotalEnergies Marketing Nigeria", ticker_symbol: "TOTAL", sector: "Oil & Gas",
    description: "Markets and distributes petroleum products across Nigeria including fuel, lubricants, and LPG.",
    current_price: 425.00, opening_price: 420.00, closing_price: 425.00, market_cap: 144_000_000_000,
    pe_ratio: 12.3, dividend_yield: 4.5, high_52_week: 480.00, low_52_week: 310.00,
    shares_outstanding: 339_000_000, founded_year: 1956, listed: true,
    website: "https://www.totalenergies.ng" },

  # Consumer Goods
  { name: "Nestlé Nigeria", ticker_symbol: "NESTLE", sector: "Consumer Goods",
    description: "Leading food and beverage manufacturer producing Milo, Maggi, Golden Morn, and other popular brands.",
    current_price: 880.00, opening_price: 870.00, closing_price: 880.00, market_cap: 697_000_000_000,
    pe_ratio: 22.0, dividend_yield: 5.7, high_52_week: 1050.00, low_52_week: 720.00,
    shares_outstanding: 793_000_000, founded_year: 1961, listed: true,
    website: "https://www.nestle-cwa.com" },

  { name: "Nigerian Breweries", ticker_symbol: "NB", sector: "Consumer Goods",
    description: "Nigeria's pioneer and largest brewing company, producer of Star, Heineken, and Gulder lagers.",
    current_price: 32.50, opening_price: 31.80, closing_price: 32.50, market_cap: 258_000_000_000,
    pe_ratio: 45.0, dividend_yield: 1.5, high_52_week: 42.00, low_52_week: 25.00,
    shares_outstanding: 7_940_000_000, founded_year: 1946, listed: true,
    website: "https://www.nbplc.com" },

  { name: "BUA Foods", ticker_symbol: "BUAFOODS", sector: "Consumer Goods",
    description: "Producer and distributor of sugar, flour, pasta, and other essential food products.",
    current_price: 145.00, opening_price: 143.00, closing_price: 145.00, market_cap: 2_610_000_000_000,
    pe_ratio: 32.0, dividend_yield: 2.8, high_52_week: 175.00, low_52_week: 95.00,
    shares_outstanding: 18_000_000_000, founded_year: 2008, listed: true,
    website: "https://www.buafoods.com" },

  # Industrial Goods
  { name: "Dangote Cement", ticker_symbol: "DANGCEM", sector: "Industrial Goods",
    description: "Africa's largest cement producer with operations in 10 countries and total capacity of 51.6 million tonnes per annum.",
    current_price: 610.00, opening_price: 600.00, closing_price: 610.00, market_cap: 10_400_000_000_000,
    pe_ratio: 18.5, dividend_yield: 3.3, high_52_week: 700.00, low_52_week: 430.00,
    shares_outstanding: 17_040_000_000, founded_year: 1992, listed: true,
    website: "https://www.dangotecement.com" },

  { name: "BUA Cement", ticker_symbol: "BUACEMENT", sector: "Industrial Goods",
    description: "Major cement manufacturer with a combined installed capacity of 11 million tonnes per annum.",
    current_price: 92.50, opening_price: 91.00, closing_price: 92.50, market_cap: 3_145_000_000_000,
    pe_ratio: 25.0, dividend_yield: 2.2, high_52_week: 110.00, low_52_week: 65.00,
    shares_outstanding: 34_000_000_000, founded_year: 2000, listed: true,
    website: "https://www.buacement.com" },

  # ICT
  { name: "MTN Nigeria Communications", ticker_symbol: "MTNN", sector: "ICT",
    description: "Nigeria's largest telecommunications company with over 80 million subscribers.",
    current_price: 230.00, opening_price: 225.00, closing_price: 230.00, market_cap: 4_681_000_000_000,
    pe_ratio: 14.0, dividend_yield: 4.3, high_52_week: 280.00, low_52_week: 165.00,
    shares_outstanding: 20_354_000_000, founded_year: 2001, listed: true,
    website: "https://www.mtnonline.com" },

  { name: "Airtel Africa", ticker_symbol: "AIRTELAFRI", sector: "ICT",
    description: "Pan-African telecommunications and mobile money services company operating in 14 African countries.",
    current_price: 2100.00, opening_price: 2050.00, closing_price: 2100.00, market_cap: 7_925_000_000_000,
    pe_ratio: 10.0, dividend_yield: 3.8, high_52_week: 2400.00, low_52_week: 1600.00,
    shares_outstanding: 3_774_000_000, founded_year: 2010, listed: true,
    website: "https://www.airtel.com.ng" },

  # Conglomerates
  { name: "Transnational Corporation", ticker_symbol: "TRANSCORP", sector: "Conglomerates",
    description: "Diversified conglomerate with interests in power, hospitality, oil & gas, and agriculture.",
    current_price: 14.20, opening_price: 13.80, closing_price: 14.20, market_cap: 578_000_000_000,
    pe_ratio: 7.0, dividend_yield: 2.1, high_52_week: 18.00, low_52_week: 8.50,
    shares_outstanding: 40_700_000_000, founded_year: 2004, listed: true,
    website: "https://www.transcorp.com" },

  # Healthcare
  { name: "Fidson Healthcare", ticker_symbol: "FIDSON", sector: "Healthcare",
    description: "Pharmaceutical company manufacturing and marketing a wide range of healthcare products.",
    current_price: 15.80, opening_price: 15.50, closing_price: 15.80, market_cap: 47_000_000_000,
    pe_ratio: 9.0, dividend_yield: 3.2, high_52_week: 20.00, low_52_week: 10.00,
    shares_outstanding: 2_970_000_000, founded_year: 1995, listed: true,
    website: "https://www.fidsonhealthcare.com" },

  # Agriculture
  { name: "Presco", ticker_symbol: "PRESCO", sector: "Agriculture",
    description: "Leading palm oil producer engaged in cultivation, extraction, refining, and fractionation of palm oil products.",
    current_price: 275.00, opening_price: 270.00, closing_price: 275.00, market_cap: 275_000_000_000,
    pe_ratio: 6.5, dividend_yield: 4.0, high_52_week: 320.00, low_52_week: 180.00,
    shares_outstanding: 1_000_000_000, founded_year: 1991, listed: true,
    website: "https://www.presco-plc.com" }
]

created_companies = {}
companies_data.each do |data|
  sector = created_sectors[data.delete(:sector)]
  company = Company.find_or_create_by!(ticker_symbol: data[:ticker_symbol]) do |c|
    c.assign_attributes(data.merge(sector: sector))
  end
  created_companies[company.ticker_symbol] = company
  puts "  ✅ Company: #{company.name} (#{company.ticker_symbol})"
end

# ── Stock Prices (last 30 days for each company) ────────────────────────────
puts "\n📊 Generating stock price history..."
created_companies.each do |ticker, company|
  base = company.current_price || 10.0
  30.downto(1) do |days_ago|
    date = Date.current - days_ago
    volatility = (rand - 0.48) * 0.04
    day_open = (base * (1 + volatility)).round(2)
    day_close = (day_open * (1 + (rand - 0.48) * 0.03)).round(2)
    day_high = [day_open, day_close].max * (1 + rand * 0.015)
    day_low = [day_open, day_close].min * (1 - rand * 0.015)
    volume = rand(500_000..15_000_000)
    change = ((day_close - day_open) / day_open * 100).round(2)

    StockPrice.find_or_create_by!(company: company, date: date) do |sp|
      sp.open = day_open
      sp.close = day_close
      sp.high = day_high.round(2)
      sp.low = day_low.round(2)
      sp.volume = volume
      sp.change_percent = change
    end
    base = day_close
  end
  puts "  📈 #{ticker}: 30-day price history"
end

# ── Dividends ────────────────────────────────────────────────────────────────
puts "\n💰 Seeding dividend data..."
dividend_data = [
  { ticker: "GTCO",       amount: 3.00, year: 2025, qualification_date: "2025-03-15", payment_date: "2025-04-10", status: :paid },
  { ticker: "GTCO",       amount: 1.50, year: 2025, qualification_date: "2025-09-20", payment_date: "2025-10-15", status: :paid, interim: true },
  { ticker: "GTCO",       amount: 3.50, year: 2026, qualification_date: "2026-03-20", payment_date: "2026-04-15", status: :announced },
  { ticker: "ZENITHBANK", amount: 3.50, year: 2025, qualification_date: "2025-04-01", payment_date: "2025-04-25", status: :paid },
  { ticker: "ZENITHBANK", amount: 4.00, year: 2026, qualification_date: "2026-04-05", payment_date: "2026-05-01", status: :announced },
  { ticker: "UBA",        amount: 1.50, year: 2025, qualification_date: "2025-03-25", payment_date: "2025-04-20", status: :paid },
  { ticker: "UBA",        amount: 2.00, year: 2026, qualification_date: "2026-03-28", payment_date: "2026-04-22", status: :announced },
  { ticker: "DANGCEM",    amount: 20.00, year: 2025, qualification_date: "2025-06-15", payment_date: "2025-07-10", status: :paid },
  { ticker: "DANGCEM",    amount: 22.00, year: 2026, qualification_date: "2026-06-20", payment_date: "2026-07-15", status: :announced },
  { ticker: "NESTLE",     amount: 45.00, year: 2025, qualification_date: "2025-05-10", payment_date: "2025-06-05", status: :paid },
  { ticker: "NESTLE",     amount: 25.00, year: 2025, qualification_date: "2025-10-15", payment_date: "2025-11-10", status: :paid, interim: true },
  { ticker: "MTNN",       amount: 9.50, year: 2025, qualification_date: "2025-04-20", payment_date: "2025-05-15", status: :paid },
  { ticker: "MTNN",       amount: 10.00, year: 2026, qualification_date: "2026-04-25", payment_date: "2026-05-20", status: :announced },
  { ticker: "SEPLAT",     amount: 25.00, year: 2025, qualification_date: "2025-09-01", payment_date: "2025-09-25", status: :paid },
  { ticker: "BUAFOODS",   amount: 3.00, year: 2026, qualification_date: "2026-05-30", payment_date: "2026-06-25", status: :announced },
  { ticker: "ACCESSCORP", amount: 1.10, year: 2025, qualification_date: "2025-04-10", payment_date: "2025-05-05", status: :paid },
  { ticker: "FBNH",       amount: 1.50, year: 2025, qualification_date: "2025-05-20", payment_date: "2025-06-15", status: :paid },
  { ticker: "AIRTELAFRI", amount: 50.00, year: 2026, qualification_date: "2026-06-10", payment_date: "2026-07-05", status: :announced },
  { ticker: "PRESCO",     amount: 10.00, year: 2025, qualification_date: "2025-07-15", payment_date: "2025-08-10", status: :paid },
]

dividend_data.each do |d|
  company = created_companies[d[:ticker]]
  next unless company
  Dividend.find_or_create_by!(
    company: company,
    year: d[:year],
    interim: d[:interim] || false
  ) do |div|
    div.amount = d[:amount]
    div.currency = "NGN"
    div.qualification_date = d[:qualification_date]
    div.payment_date = d[:payment_date]
    div.status = d[:status]
  end
  puts "  💵 #{d[:ticker]}: ₦#{d[:amount]} (#{d[:year]}#{d[:interim] ? ' interim' : ''})"
end

# ── News Articles ────────────────────────────────────────────────────────────
puts "\n📰 Seeding news articles..."
news = [
  { title: "GTCO Posts Record N1.2 Trillion Profit, Declares ₦3.50 Final Dividend",
    summary: "Guaranty Trust Holding Company has reported its strongest financial year to date, with profit after tax surging 85% to N1.2 trillion. The board has recommended a final dividend of ₦3.50 per share.",
    category: "Earnings", source: "BusinessDay", featured: true, published_at: 2.days.ago },
  { title: "CBN Holds MPR at 24.75% Amid Declining Inflation",
    summary: "The Central Bank of Nigeria's Monetary Policy Committee voted to retain the benchmark interest rate at 24.75%, citing early signs of disinflation as headline inflation eases to 28.4%.",
    category: "Economy", source: "ThisDay", featured: true, published_at: 5.hours.ago },
  { title: "Dangote Cement Commissions New 6 MTPA Plant in Ogun State",
    summary: "Dangote Cement has officially commissioned its new 6 million tonnes per annum plant in Ogun State, bringing total domestic capacity to 35.25 MTPA and reinforcing its position as Africa's largest cement producer.",
    category: "Corporate", source: "Nairametrics", featured: false, published_at: 1.day.ago },
  { title: "MTN Nigeria Crosses 85 Million Subscriber Milestone",
    summary: "MTN Nigeria has announced it has surpassed 85 million subscribers, driven by aggressive 4G network expansion and growing adoption of mobile data services across rural communities.",
    category: "Telecoms", source: "TechCabal", featured: false, published_at: 3.days.ago },
  { title: "Nigerian Stock Exchange ASI Surges Past 100,000 Points for First Time",
    summary: "The NGX All-Share Index broke through the historic 100,000-point barrier for the first time, buoyed by strong corporate earnings and renewed foreign portfolio investment inflows.",
    category: "Market", source: "Bloomberg", featured: true, published_at: 6.hours.ago },
  { title: "BUA Foods Reports 120% Revenue Growth, Expands Sugar Refinery",
    summary: "BUA Foods has reported a 120% year-on-year increase in revenue to ₦800 billion, driven by surging demand for its sugar, flour, and pasta products. The company also announced a ₦50 billion refinery expansion.",
    category: "Earnings", source: "Punch", featured: false, published_at: 2.days.ago },
  { title: "Foreign Investors Return to Nigerian Equities with ₦45 Billion Inflow",
    summary: "Foreign portfolio investors have poured ₦45 billion into Nigerian equities in the past month, the highest in three years, as improved FX transparency and attractive valuations boost confidence.",
    category: "Market", source: "Financial Times", featured: false, published_at: 4.days.ago },
  { title: "Airtel Africa to Spin Off Mobile Money Business in 2026",
    summary: "Airtel Africa has announced plans to spin off its mobile money division into a separately listed entity by Q4 2026, potentially unlocking significant shareholder value.",
    category: "Corporate", source: "Reuters", featured: true, published_at: 12.hours.ago },
  { title: "SEC Nigeria Approves New Rules for Digital Asset Trading",
    summary: "The Securities and Exchange Commission has released its final framework for the regulation of digital asset exchanges, paving the way for licensed crypto trading in the country.",
    category: "Regulation", source: "CoinDesk", featured: false, published_at: 1.week.ago },
  { title: "Presco Plc Delivers 95% Profit Growth on Rising Palm Oil Demand",
    summary: "Presco Plc has posted a 95% rise in profit before tax, benefiting from elevated global palm oil prices and increased domestic consumption of vegetable oils.",
    category: "Earnings", source: "BusinessDay", featured: false, published_at: 5.days.ago }
]

news.each do |n|
  article = NewsArticle.find_or_create_by!(title: n[:title]) do |article|
    article.summary = n[:summary]
    article.category = n[:category]
    article.source = n[:source]
    article.featured = n[:featured]
    article.published_at = n[:published_at]
  end
  n[:summary].scan(/\b[A-Z]{2,10}\b/).each do |ticker|
    company = created_companies[ticker]
    CompanyNews.find_or_create_by!(news_article: article, company: company) if company
  end
  puts "  📄 #{n[:title][0..60]}..."
end

# ── Educational Content ─────────────────────────────────────────────────────
puts "\n📚 Seeding educational content..."
lessons = [
  { title: "How Dividend Qualification Dates Work", summary: "Understand qualification dates, closure dates, and payment dates so you know when a stock must be held to receive a declared dividend.", category: "Dividends", difficulty_level: :beginner, featured: true, published_at: 1.day.ago },
  { title: "Reading PE Ratios on Nigerian Banks", summary: "Learn how to compare price-to-earnings ratios across banks while accounting for earnings quality, provisioning, and interest-rate cycles.", category: "Valuation", difficulty_level: :intermediate, featured: true, published_at: 2.days.ago },
  { title: "Building a Balanced NGX Watchlist", summary: "A practical approach to tracking banks, consumer names, industrials, telecoms, and dividend stocks without overloading your dashboard.", category: "Portfolio", difficulty_level: :beginner, featured: false, published_at: 3.days.ago },
  { title: "What Market Capitalization Tells You", summary: "Use market cap to understand company size, liquidity expectations, index influence, and concentration risk in the Nigerian market.", category: "Basics", difficulty_level: :beginner, featured: false, published_at: 4.days.ago }
]

lessons.each do |lesson|
  EducationalContent.find_or_create_by!(title: lesson[:title]) do |content|
    content.summary = lesson[:summary]
    content.category = lesson[:category]
    content.difficulty_level = lesson[:difficulty_level]
    content.featured = lesson[:featured]
    content.published_at = lesson[:published_at]
  end
  puts "  📘 #{lesson[:title]}"
end

# ── Admin User ───────────────────────────────────────────────────────────────
puts "\n👤 Creating admin user..."
admin = User.find_or_create_by!(email: "admin@stiip.ng") do |u|
  u.first_name = "Admin"
  u.last_name = "STIIP"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = :admin
  u.confirmed_at = Time.current
end
puts "  ✅ Admin: admin@stiip.ng / password123"

# ── Demo User ────────────────────────────────────────────────────────────────
demo = User.find_or_create_by!(email: "demo@stiip.ng") do |u|
  u.first_name = "Chidi"
  u.last_name = "Okonkwo"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = :premium
  u.confirmed_at = Time.current
end
puts "  ✅ Demo: demo@stiip.ng / password123"

# ── Demo Watchlist ───────────────────────────────────────────────────────────
watchlist = Watchlist.find_or_create_by!(user: demo, name: "My Core Holdings")

%w[GTCO DANGCEM MTNN BUAFOODS SEPLAT].each do |ticker|
  company = created_companies[ticker]
  WatchlistItem.find_or_create_by!(watchlist: watchlist, company: company) if company
end
puts "  📋 Watchlist created with 5 stocks"

puts "\n🎉 Seeding complete! #{Company.count} companies, #{StockPrice.count} prices, #{Dividend.count} dividends, #{NewsArticle.count} articles."
