# Implementation Plan: Access Control, Plan Limits, and API Monetization

## Goal

Convert NoraCapital from mostly-open access into a tiered product:

- Guests can browse public marketing/discovery pages, but sensitive or valuable market intelligence prompts login.
- Newly registered users are assigned the Free plan automatically.
- Free users get the limited feature set advertised on `/pricing`.
- Premium users, analysts, and admins get full platform access.
- External API access becomes a monetizable feature with real API keys, authentication, rate limits, and plan-based scopes.

## Current State Observed

- Users already have roles via `User.role`: `free`, `premium`, `analyst`, `admin`.
- Subscriptions already exist via `Subscription.plan`: `free`, `premium`.
- Pricing currently advertises:
  - Free: 1 watchlist, up to 5 stocks, 30-day price history, basic dividend calendar, market news feed, educational articles.
  - Premium: unlimited watchlists/stocks, full historical price data, advanced dividend analytics, alerts, CSV export, priority support, AI insights.
- Some premium gating already exists in company details, but it is incomplete.
- Watchlists, dashboard, notifications, profile already require login.
- Public pages like companies, dividends, market, screener, news, learn, and search are broadly accessible.
- API endpoints already exist under `/api/v1`, but authentication is currently a hardcoded `test_token`.

## Access Model

### Guest Access

Guests should be able to access:

- Home page
- Pricing page
- About, features, contact, terms, privacy, disclaimer
- Login and signup
- Limited company index preview
- Limited market overview preview
- Limited news/education index preview

Guests should not access:

- Company detail intelligence beyond public summary
- Full price history
- Dividends detail data
- Screener results
- Watchlists
- Dashboard
- Notifications
- Profile/settings
- Search results beyond a small teaser
- API endpoints

Guest denial message:

> You must be logged in to access this information.

Primary CTA:

> Log in

Secondary CTA:

> Create free account

### Free User Access

Free users should get exactly the basic plan promised on `/pricing`:

- 1 watchlist
- Up to 5 stocks in that watchlist
- 30-day price history only
- Basic dividend calendar
- Market news feed
- Educational articles
- Basic company profiles
- Basic search

Free users should be blocked from:

- More than 1 watchlist
- More than 5 watchlist items
- Full historical prices
- Advanced screener filters/results
- Advanced dividend analytics
- Yield rankings
- CSV exports
- Price alerts
- API access, unless a future paid API add-on is introduced
- Premium-only insights

Free denial message:

> This feature requires Premium Subscription.

Primary CTA:

> Upgrade to Premium

### Premium User Access

Premium users should access:

- All public and authenticated UI features
- Unlimited watchlists and watchlist items
- Full historical price data
- Advanced screener
- Advanced dividend analytics and rankings
- CSV exports
- Alerts
- API keys and API usage dashboard
- API endpoints within plan limits

### Analyst/Admin Access

Analysts and admins should be treated as Premium for user-facing access.

Admins additionally keep access to `/admin`.

## Implementation Phases

## Phase 1: Centralize Authorization

Create a single policy layer instead of scattering `if premium_user?` checks everywhere.

Recommended files:

- Add `app/models/access_policy.rb`
- Update `app/controllers/application_controller.rb`
- Update `app/controllers/concerns/authenticatable.rb`

Policy methods:

- `guest?`
- `free_user?`
- `premium_user?`
- `admin_or_analyst?`
- `can_view_company_details?`
- `can_view_full_price_history?`
- `can_use_screener?`
- `can_use_advanced_dividends?`
- `can_export_data?`
- `can_create_watchlist?`
- `can_add_watchlist_item?`
- `can_manage_api_keys?`
- `can_use_api?`

Controller helpers:

- `require_login_for_feature!`
- `require_premium_for_feature!`
- `current_access_policy`

## Phase 2: Ensure Free Plan on Signup

Add automatic free subscription provisioning after user creation.

Recommended implementation:

- Add callback in `User`:
  - `after_create :ensure_free_subscription!`
- Create subscription with:
  - `plan: :free`
  - `status: :active`
  - `started_at: Time.current` if the column exists or is added
- Ensure role remains `free` unless explicitly upgraded.

Also add a data backfill migration or runner task for existing users:

- Every user without a subscription gets an active free subscription.
- Premium/admin/analyst users should not be downgraded.

## Phase 3: Gate Public UI Resources

Update controllers to enforce guest/free/premium access.

### Companies

Files:

- `app/controllers/companies_controller.rb`
- `app/views/companies/index.html.erb`
- `app/views/companies/show.html.erb`

Rules:

- Guests can view company index preview.
- Guests hitting full company show should see a login-required block or redirect.
- Free users can view basic company profile and 30-day price history.
- Premium users can view full company details and full history.

### Market

Files:

- `app/controllers/market_controller.rb`
- `app/views/market/index.html.erb`

Rules:

- Guests see top-level market snapshot only.
- Free users see basic market data.
- Premium users see full market intelligence.

### Dividends

Files:

- `app/controllers/dividends_controller.rb`
- `app/views/dividends/index.html.erb`

Rules:

- Guests must log in for dividend details.
- Free users see basic calendar.
- Premium users see advanced analytics, yield rankings, and full history.

### Screener

Files:

- `app/controllers/screener_controller.rb`
- `app/views/screener/index.html.erb`

Rules:

- Guests must log in.
- Free users can see a locked/premium upsell state, or a minimal basic screener if desired.
- Premium users get full screener access.

### News and Learn

Files:

- `app/controllers/news_articles_controller.rb`
- `app/controllers/educational_contents_controller.rb`
- Matching views

Rules:

- Guests can view index and limited teaser content.
- Free users can read standard articles.
- Premium-only articles require Premium if that flag is added later.

### Search

Files:

- `app/controllers/search_controller.rb`
- `app/views/search/index.html.erb`

Rules:

- Guests see limited results or a login-required state.
- Free users get basic search.
- Premium users get full search results.

## Phase 4: Enforce Free Plan Limits

### Watchlists

Files:

- `app/controllers/watchlists_controller.rb`
- `app/controllers/watchlist_items_controller.rb`

Rules:

- Free users may create only 1 watchlist.
- Free users may add only 5 companies total to their watchlist.
- Premium users have no practical platform limit.

Add request specs for:

- Guest blocked from watchlists.
- Free user blocked on second watchlist.
- Free user blocked on sixth stock.
- Premium user allowed beyond free limits.

### Price History

Files:

- `app/controllers/companies_controller.rb`
- `app/controllers/api/v1/prices_controller.rb`

Rules:

- Free users get 30 days.
- Premium users get full available history.

### CSV Export

If export endpoints exist or are added:

- Free users blocked.
- Premium users allowed.

## Phase 5: Build Real API Monetization

Replace the hardcoded API token with real API key management.

### Database

Add table `api_keys`:

- `id: uuid`
- `user_id: uuid`
- `name: string`
- `token_digest: string`
- `token_prefix: string`
- `last_used_at: datetime`
- `revoked_at: datetime`
- `expires_at: datetime`
- `requests_count: integer`
- `rate_limit_per_minute: integer`
- `created_at`
- `updated_at`

Security:

- Store only a digest of the token.
- Show the raw token once on creation.
- Use a prefix for display and lookup.

### Model

Add `app/models/api_key.rb`.

Responsibilities:

- Generate secure tokens.
- Digest tokens.
- Validate active/non-revoked keys.
- Associate keys with users.
- Delegate plan checks to user/subscription.

### API Authentication

Update:

- `app/controllers/api/v1/base_controller.rb`

Replace:

- Hardcoded `test_token`

With:

- `Authorization: Bearer nora_live_xxx`
- Lookup API key by prefix.
- Secure compare token digest.
- Reject revoked/expired keys.
- Reject users without API access.

### API Access Plans

Initial recommendation:

- Free: no API access.
- Premium: API access included with modest limits.
- Future Business/API plan: higher limits, commercial use, bulk endpoints.

Premium API defaults:

- 60 requests/minute
- 5,000 requests/month
- JSON only
- Attribution required if republishing

Future API tier:

- 600 requests/minute
- 250,000 requests/month
- Bulk endpoints
- Commercial license
- Priority support

### API Key UI

Add authenticated pages:

- `GET /api_keys`
- `POST /api_keys`
- `DELETE /api_keys/:id`

Files:

- `app/controllers/api_keys_controller.rb`
- `app/views/api_keys/index.html.erb`

Rules:

- Guests blocked.
- Free users see upsell.
- Premium users can create/revoke keys.

### API Endpoints

Keep existing `/api/v1` routes and secure them:

- `GET /api/v1/companies`
- `GET /api/v1/companies/:ticker`
- `GET /api/v1/companies/:ticker/prices`
- `GET /api/v1/companies/:ticker/dividends`
- `GET /api/v1/dividends`
- `GET /api/v1/news`
- `GET /api/v1/news/:slug`
- `GET /api/v1/search`

Add monetizable endpoints later:

- `GET /api/v1/market/summary`
- `GET /api/v1/screener`
- `GET /api/v1/companies/:ticker/fundamentals`
- `GET /api/v1/dividends/rankings`

## Phase 6: Rate Limiting and Abuse Control

Update Rack Attack:

- Keep IP throttles.
- Add API-key based throttle.
- Add stricter throttle for invalid API token attempts.

Files:

- `config/initializers/rack_attack.rb`

Rules:

- Invalid API tokens: strict throttle per IP.
- Valid API keys: throttle by key/token prefix.
- Premium: default API rate.
- Future Business/API: higher API rate.

## Phase 7: UX for Locked Features

Create reusable locked-feature partial/component.

Recommended:

- `app/views/shared/_locked_feature.html.erb`

Inputs:

- `title`
- `message`
- `required_plan`
- `cta_label`
- `cta_path`

Use it across:

- Company detail premium sections
- Dividends analytics
- Screener
- Export buttons
- API key page for Free users

## Phase 8: Tests

Add request specs for:

- Guest access restrictions.
- Free plan access restrictions.
- Premium full access.
- Signup creates active Free subscription.
- API rejects missing token.
- API rejects invalid token.
- API rejects Free user API key attempts.
- API allows Premium API key.
- API rate limiting path.

Recommended files:

- `spec/requests/access_control_spec.rb`
- `spec/requests/watchlist_limits_spec.rb`
- `spec/requests/api_authentication_spec.rb`
- `spec/models/api_key_spec.rb`
- `spec/models/user_subscription_spec.rb`

## Implementation Order

1. Add centralized policy/helpers.
2. Add automatic Free subscription provisioning.
3. Gate guest access on sensitive pages.
4. Enforce Free user limits.
5. Build API key model and migration.
6. Replace API `test_token` auth.
7. Add API key management UI.
8. Add Rack Attack API throttling.
9. Add request/model specs.
10. Update `/pricing` copy if API access is included in Premium or separated into a future API tier.

## Deployment Notes

- This plan should work with the existing single-database Dokku production setup.
- New API keys table will be created via normal Rails migration.
- No separate API database is required.
- If API usage grows, usage counters can later move to Redis or a dedicated analytics table, but that is unnecessary for the first monetizable version.

## Open Product Decisions Before Coding

1. Should Premium include API access immediately, or should API access be a separate Business/API tier?
2. Should guests be redirected to login, or should they remain on-page with a locked-content prompt?
3. Should Free users get a minimal screener, or should the screener be Premium-only?
4. What monthly API request quota should Premium users receive?
5. Should API access allow commercial redistribution, or only personal/private use?


Decision Updates
API should be a separate Business/API tier
Yes. That is cleaner. Premium should be for individual investors. Business/API should be for companies, fintechs, media platforms, investment clubs, analysts, and developers.
Recommended tiers:
Free
Premium
Business/API
Admin/Internal
Use locked-content prompts, not redirects
Agreed. This is better for conversion because users see what they are missing.
Pattern:
This information is available to logged-in users.
[Log in] [Create free account]
For Free users:
This feature requires Premium.
[Upgrade to Premium]
For API/Business:
This feature requires a Business/API plan.
[Contact Sales] or [Upgrade]
Screener should be Premium-only
Agreed. Screener is a high-value feature. It should be a conversion driver.

API quota recommendation
Since API is a separate paid tier, I would not give Premium users API access by default.

Recommended Business/API starter quotas:
Business/API Starter: 100,000 requests/month
Rate limit: 120 requests/minute
Then later:
Business/API Growth: 500,000 requests/month
Rate limit: 600 requests/minute

Business/API Enterprise: custom
Rate limit: custom
For a Nigerian market intelligence API, this is generous enough for real products but not reckless.
Commercial redistribution
I think yes, but only on the Business/API tier and with clear licensing terms.
My recommendation:
Premium: personal/internal use only, no API.
Business/API: commercial use allowed.
Redistribution allowed only if their product adds value and does not simply clone/resell NoraCapital’s raw database.
Require attribution unless waived by Enterprise agreement.
Prohibit bulk republication of the full dataset as a competing API/data dump.
In plain terms: let them build apps, dashboards, newsletters, internal tools, and customer-facing financial products with your data. Do not let them repackage your entire API as their own API.
Best license wording direction:
Business/API customers may use NoraCapital API data in commercial products,
customer-facing dashboards, internal tools, reports, and applications, provided
the data is not resold as a standalone raw data feed or substantially similar
market intelligence database.
Updated Product Model
Free
- Basic access after signup
- 1 watchlist
- 5 stocks
- 30-day price history
- Basic company data
- Basic news/education

Premium
- All investor-facing features
- Screener
- Full history
- Unlimited watchlists
- Dividend analytics
- Alerts
- CSV exports
- Premium insights

Business/API
- Everything in Premium
- API keys
- Commercial API usage
- Higher quotas
- Bulk/data endpoints
- Priority support
- Optional white-label/data licensing