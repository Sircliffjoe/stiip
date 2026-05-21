Build a modern, scalable, production-ready Nigerian Stock Intelligence Platform focused on retail investors, dividend tracking, market education, and simplified investment intelligence.

The platform should be MVP-first but architected for future scalability into a full fintech investment intelligence ecosystem.

========================================================
CORE PRODUCT VISION
========================================================

The platform is NOT a brokerage or stock trading platform initially.

It is:
- a Nigerian stock intelligence platform,
- dividend tracking platform,
- market information hub,
- educational investment ecosystem,
- and retail investor companion.

The goal is to simplify Nigerian stock investing for everyday users.

Users should be able to:
- discover listed companies,
- track stock prices,
- monitor dividend payouts,
- follow market news,
- create watchlists,
- receive alerts,
- and understand investment information in beginner-friendly language.

The platform should feel like:
- Yahoo Finance,
- Investing.com,
- TradingView,
but simplified and localized for Nigerian investors.

========================================================
IMPORTANT ARCHITECTURE PRINCIPLES
========================================================

The application MUST remain fully within the Rails ecosystem.

Use:
- Rails-native architecture,
- server-rendered pages,
- Hotwire-first development,
- minimal JavaScript philosophy,
- reusable ViewComponents,
- Turbo Streams,
- Stimulus controllers,
- and maintainable monolithic architecture.

Favor:
- convention over configuration,
- maintainability,
- scalability,
- performance,
- clean architecture,
- and developer productivity.

DO NOT build a frontend SPA.

DO NOT use:
- React,
- Vue,
- Next.js,
- Angular,
- Inertia,
- or frontend-heavy ecosystems.

========================================================
TECH STACK (STRICT REQUIREMENT)
========================================================

Use ONLY:

- Ruby on Rails 8+
- PostgreSQL
- TailwindCSS
- Hotwire
  - Turbo
  - Stimulus
- Importmaps ONLY
- Redis
- Sidekiq
- ActionCable
- Devise
- Pundit
- Pagy
- ViewComponent
- ActiveStorage
- RSpec
- FactoryBot
- Faker
- Rubocop
- Brakeman
- Docker
- Kamal deployment readiness

Optional:
- Solid Queue instead of Sidekiq if preferred

========================================================
JAVASCRIPT REQUIREMENTS
========================================================

Use:
- Importmaps ONLY.

Avoid:
- Node-heavy tooling,
- JavaScript bundlers,
- complex frontend compilation systems.

Use Stimulus for:
- dropdowns,
- tabs,
- modals,
- filters,
- live search,
- lightweight UI interactions.

Use Turbo Streams for:
- realtime notifications,
- live dashboard updates,
- watchlist changes,
- and live UI refreshes.

========================================================
DESIGN PHILOSOPHY
========================================================

The UI should feel:
- modern,
- premium,
- financial-tech inspired,
- clean,
- educational,
- and mobile-first.

Use:
- TailwindCSS
- responsive layouts
- reusable components
- financial dashboards
- minimalist cards
- tables
- charts
- badges
- modern typography
- dark/light mode

Prioritize:
- clarity,
- simplicity,
- readability,
- and accessibility.

========================================================
APPLICATION TYPE
========================================================

Build:
- responsive web application,
- mobile-first experience,
- PWA-ready architecture,
- API-ready backend.

Even though pages are server-rendered, the backend should be structured so future mobile apps can consume APIs.

========================================================
MVP FEATURES
========================================================

========================================================
1. AUTHENTICATION SYSTEM
========================================================

Implement:
- registration
- login
- password reset
- email verification
- remember me
- profile management

Roles:
- Admin
- Analyst
- Premium User
- Free User

Use:
- Devise
- Pundit

========================================================
2. DASHBOARD
========================================================

Build a modern financial dashboard showing:
- market overview,
- top gainers,
- top losers,
- most traded stocks,
- latest dividend announcements,
- featured insights,
- market news,
- watchlist summaries.

Dashboard should be optimized for:
- mobile devices,
- slow internet,
- and Nigerian users.

========================================================
3. COMPANIES MODULE
========================================================

Create detailed company pages containing:
- company logo,
- ticker symbol,
- sector,
- stock price,
- historical prices,
- market cap,
- PE ratio,
- dividend yield,
- annual reports,
- qualification dates,
- payment dates,
- investor relations links,
- educational explanations.

IMPORTANT:
Translate financial jargon into beginner-friendly explanations.

Example:
Instead of:
“PE Ratio: 4.3”

Display:
“This stock may currently be undervalued compared to similar companies.”

========================================================
4. DIVIDEND INTELLIGENCE SYSTEM
========================================================

This is one of the most important features.

Implement:
- dividend calendar,
- upcoming dividends,
- qualification dates,
- payment dates,
- dividend yields,
- historical dividend records,
- dividend ranking system.

Allow filtering by:
- sector,
- yield,
- company,
- date,
- consistency.

========================================================
5. WATCHLIST SYSTEM
========================================================

Users should be able to:
- follow stocks,
- create watchlists,
- receive alerts,
- track dividend announcements,
- monitor stock activity.

========================================================
6. NOTIFICATIONS & ALERTS
========================================================

Implement:
- in-app notifications,
- email notifications,
- realtime dashboard alerts.

Use:
- ActionCable
- Turbo Streams
- Redis
- Sidekiq

Alert triggers:
- dividend announcements,
- stock price changes,
- market news,
- earnings releases,
- watchlist activity.

========================================================
7. MARKET NEWS MODULE
========================================================

Create a news aggregation system.

Features:
- categorized news,
- tagged articles,
- searchable news,
- company-linked articles,
- featured stories.

Support:
- manual admin publishing,
- automated ingestion architecture later.

========================================================
8. EDUCATIONAL INSIGHTS MODULE
========================================================

Create beginner-friendly educational content system.

Admins/analysts should publish:
- market guides,
- investment tutorials,
- stock analyses,
- dividend insights,
- beginner investing content.

Support:
- rich text editor,
- categories,
- tags,
- featured articles,
- embedded charts.

========================================================
9. ADMIN PANEL
========================================================

Create powerful admin backend.

Admins should manage:
- users,
- companies,
- stock prices,
- dividends,
- news,
- educational content,
- notifications,
- analytics,
- data ingestion sources.

Dashboard analytics should show:
- user growth,
- active users,
- premium subscriptions,
- trending stocks,
- watchlist activity.

========================================================
10. SEARCH SYSTEM
========================================================

Implement global search for:
- companies,
- ticker symbols,
- articles,
- sectors,
- dividends.

Use:
- PostgreSQL full-text search initially.

Architecture should support:
- Elasticsearch/OpenSearch later.

========================================================
11. STOCK DATA INGESTION ARCHITECTURE
========================================================

IMPORTANT:
This is the core technical foundation.

The platform is NOT generating stock data.
It is aggregating, normalizing, structuring, and presenting data from multiple reputable sources.

========================================================
DATA SOURCES
========================================================

Design a provider-agnostic ingestion system supporting:
- NGX data,
- company investor relations pages,
- CSV uploads,
- financial APIs,
- news feeds,
- manual admin uploads,
- scraping pipelines.

Potential sources:
- Nigerian Exchange Group (NGX)
- company investor relations pages
- SEC releases
- financial APIs
- corporate reports

========================================================
MVP DATA STRATEGY
========================================================

Use a hybrid model:
- manual uploads,
- scheduled jobs,
- scraping,
- and APIs.

DO NOT depend entirely on realtime APIs.

========================================================
DATA UPDATE FREQUENCY
========================================================

MVP update schedule:
- stock prices → daily
- market summary → daily
- dividend announcements → as announced
- news → hourly
- notifications → realtime

========================================================
INGESTION ARCHITECTURE
========================================================

Implement provider-based architecture.

Example:

StockDataProvider
  -> NgxProvider
  -> CsvProvider
  -> ApiProvider
  -> ScraperProvider

Each provider should return normalized data structures.

DO NOT tightly couple ingestion logic to models.

========================================================
SERVICE OBJECT REQUIREMENTS
========================================================

Use service objects for:
- API ingestion
- scraping
- normalization
- CSV parsing
- data transformation
- validations
- sync orchestration

Example structure:

app/services/
  stock_data/
    fetch_market_summary_service.rb
    fetch_dividends_service.rb
    normalize_stock_data_service.rb
    parse_csv_service.rb
    scrape_ngx_service.rb

========================================================
BACKGROUND JOBS
========================================================

Use Sidekiq for:
- stock synchronization
- news syncing
- dividend updates
- notification delivery
- scraping jobs

Example jobs:

app/jobs/
  sync_stock_prices_job.rb
  sync_dividends_job.rb
  sync_market_news_job.rb

========================================================
12. ANALYTICS & METRICS
========================================================

Track:
- most viewed stocks,
- trending sectors,
- watchlist frequency,
- dividend interest,
- engagement metrics,
- premium conversions.

========================================================
13. SUBSCRIPTION SYSTEM
========================================================

Prepare monetization architecture.

Plans:
- Free
- Premium

Premium features:
- advanced alerts,
- premium insights,
- deeper analytics,
- unlimited watchlists,
- enhanced dividend intelligence.

Prepare architecture for:
- Paystack
- Stripe

========================================================
14. API ARCHITECTURE
========================================================

Create versioned API structure:

/api/v1/

Even though frontend is server-rendered.

Future mobile apps should integrate easily.

Use:
- serializers
- token auth architecture

========================================================
15. PERFORMANCE OPTIMIZATION
========================================================

Implement:
- Redis caching,
- fragment caching,
- eager loading,
- query optimization,
- pagination,
- background processing.

Optimize for:
- low bandwidth users,
- mobile devices,
- Nigerian internet conditions.

========================================================
16. SECURITY
========================================================

Implement:
- CSRF protection,
- rate limiting,
- secure sessions,
- authorization policies,
- account lockout,
- encrypted credentials,
- audit logs,
- admin activity tracking.

========================================================
17. CHARTS & VISUALIZATION
========================================================

Use Rails-friendly charting tools ONLY.

Preferred:
- Chartkick
- Groupdate
- Chart.js via Importmaps

Avoid frontend-heavy charting frameworks.

Implement:
- stock history charts,
- dividend trend charts,
- market sector charts,
- watchlist performance charts.

========================================================
18. DATABASE DESIGN
========================================================

Design scalable schemas for:
- users
- subscriptions
- companies
- sectors
- stock_prices
- dividends
- watchlists
- notifications
- news_articles
- market_events
- reports
- audit_logs

Use:
- UUIDs
- indexes
- constraints
- foreign keys

========================================================
19. FUTURE-READY ARCHITECTURE
========================================================

Architect for future expansion into:
- AI investment assistant,
- recommendation engines,
- brokerage integrations,
- portfolio syncing,
- WhatsApp alerts,
- mobile apps,
- social investing,
- community discussions.

DO NOT fully implement these now.

Only ensure architecture is extensible.

========================================================
20. CODE QUALITY REQUIREMENTS
========================================================

Strictly follow:
- service objects,
- POROs,
- query objects,
- presenters/decorators,
- reusable concerns,
- skinny controllers,
- maintainable models,
- clean architecture.

Avoid:
- fat controllers,
- duplicated logic,
- tightly coupled code.

========================================================
DEPLOYMENT REQUIREMENTS
========================================================

Prepare deployment using:
- Docker
- Kamal
- PostgreSQL
- Redis

Support:
- staging
- production
- CI/CD pipelines

========================================================
SEED DATA
========================================================

Seed:
- Nigerian listed companies,
- sectors,
- dividend samples,
- stock price history,
- market news,
- admin users.

Include:
- GTCO
- Zenith Bank
- UBA
- Dangote Cement
- MTN Nigeria
- Nestlé Nigeria
- Seplat

========================================================
FINAL EXPECTATION
========================================================

Generate:
- complete Rails application structure,
- migrations,
- models,
- controllers,
- views,
- ViewComponents,
- service objects,
- jobs,
- policies,
- routes,
- Tailwind UI,
- admin backend,
- serializers,
- tests,
- Docker setup,
- deployment setup,
- API architecture,
- documentation.

The platform must be:
- production-grade,
- scalable,
- secure,
- maintainable,
- performant,
- investor-demo ready,
- and optimized for long-term fintech growth.