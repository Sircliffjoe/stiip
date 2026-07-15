# NoraCapital

Nigerian Stock Intelligence Platform — your smart companion for investing in Nigerian stocks.

## Prerequisites

- Ruby 3.3.10 (see `.ruby-version`)
- PostgreSQL
- Node / npm (for Tailwind CSS compilation)

## Quickstart (Development)

1. Install dependencies:

```bash
gem install bundler
bundle install
```

2. Configure database (adjust `config/database.yml` as needed):

```bash
bin/rails db:create db:migrate db:seed
```

3. Run the server:

```bash
bin/dev
```

## Testing

```bash
bundle exec rspec
```

## Docker (Production)

Build and run the container (ensure `RAILS_MASTER_KEY` is available):

```bash
docker build -t noracapital .
docker run -d -p 80:80 -e RAILS_MASTER_KEY=<master_key> --name noracapital noracapital
```

## Email Delivery (Brevo)

Production email is sent through the Brevo Transactional Email API using the custom Action Mailer delivery method in `lib/brevo_delivery.rb`.

Required production environment variables:

```bash
BREVO_API_KEY=<your_brevo_api_key>
BREVO_SENDER_EMAIL=noreply@noracapital.com.ng
BREVO_SENDER_NAME=NoraCapital
APP_HOST=www.noracapital.com.ng
APP_PROTOCOL=https
```

For Dokku:

```bash
dokku config:set noracapital \
  BREVO_API_KEY=<your_brevo_api_key> \
  BREVO_SENDER_EMAIL=noreply@noracapital.com.ng \
  BREVO_SENDER_NAME=NoraCapital \
  APP_HOST=www.noracapital.com.ng \
  APP_PROTOCOL=https
```

Make sure the sender domain/email is verified in Brevo before sending password reset, confirmation, or account emails.

## Market Data, News, and Dividends

NoraCapital uses provider classes under `app/services/data_ingestion/providers`. For production, configure at least EODHD:

```bash
EODHD_API_KEY=<your_eodhd_api_key>
EODHD_EXCHANGE_CODE=XNSA
EODHD_NEWS_TAGS=NIGERIA,ECONOMY,FINANCIAL MARKETS,INVESTMENT,BANKING
EODHD_NEWS_SYMBOL_LIMIT=10
SOLID_QUEUE_IN_PUMA=1
```

If EODHD uses a different suffix for Nigerian equities on your plan, provide fallbacks:

```bash
EODHD_EXCHANGE_CODES=XNSA,LAG,NSE
```

Production sync commands:

```bash
bin/rails runner 'SyncNewsJob.perform_now("market")'
bin/rails runner 'SyncDividendsJob.perform_now("eodhd")'
```

## Deployment

Deployed via Coolify on VPS. See deployment documentation for details.

## License

All rights reserved.
