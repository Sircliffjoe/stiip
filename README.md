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

## Deployment

Deployed via Coolify on VPS. See deployment documentation for details.

## License

All rights reserved.
