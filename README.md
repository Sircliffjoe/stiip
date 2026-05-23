# stiip

Minimal README to get the application running, tested, and deployed.

Prerequisites:
- Ruby 3.3.10 (see .ruby-version)
- PostgreSQL (local development)
- Node / npm if you work with JS tooling for assets

Quickstart (development):

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
bin/rails server
```

Testing:

```bash
bundle exec rspec
```

CI:
- A GitHub Actions workflow is provided at `.github/workflows/ci.yml` to run the test
	suite on push and PRs.

Docker (production-style image):

Build and run the container (ensure `RAILS_MASTER_KEY` is available):

```bash
docker build -t stiip .
docker run -d -p 80:80 -e RAILS_MASTER_KEY=<master_key> --name stiip stiip
```

Kamal deployment:
- A minimal `kamal.yml` is included to deploy the existing `Dockerfile` with Kamal.
	See https://kamal-deploy.org for detailed usage.

Further documentation:
- See `PHASE_1_COMPLETION.md` and related roadmap files for project details.
