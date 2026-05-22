# Phase 1 Verification Guide

## Quick Test Checklist

### 1. Database Setup ✅
```bash
cd /home/eventro/Project/stiip
rails db:reset           # Creates, migrates, seeds
```

**Expected Output**: Should show seed success (sectors, companies, users).

---

### 2. User Registration Flow ✅

**Step 1: Visit signup page**
- Navigate: http://localhost:3000/users/sign_up
- Fill form:
  - Email: `testuser@example.com`
  - Password: `SecurePass123!`
  - First Name: `John`
  - Last Name: `Investor`
- Click "Sign up"

**Expected**: 
- Redirected to confirmation page
- Email confirmation message shown in console or Sidekiq/Mailbox

**Step 2: Confirm email**
```bash
# In Rails console:
rails console
user = User.find_by(email: 'testuser@example.com')
user.confirm
# or
user.update(confirmed_at: Time.current)
```

**Step 3: Login**
- Navigate: http://localhost:3000/users/sign_in
- Enter email and password
- Click "Log in"

**Expected**: Redirected to dashboard, "Signed in successfully" flash message.

---

### 3. Role-Based Access Control ✅

**Test Free User**
```bash
rails console
free_user = User.find_by(email: 'testuser@example.com')
free_user.role          # => :free
free_user.free?         # => true
free_user.admin?        # => false
```

**Test Role Switching to Admin**
```bash
free_user.update(role: :admin)
free_user.admin?        # => true
free_user.analyst?      # => false (only this role)
```

**Test Admin Access**
- As free user: Visit http://localhost:3000/admin → Should see "Access denied" and redirect
- As admin: Visit http://localhost:3000/admin → Should load admin dashboard

---

### 4. Pundit Authorization ✅

**In Admin Controller (example)**
```ruby
class Admin::UsersController < Admin::ApplicationController
  # Inherits require_admin! which checks admin? || analyst?
  
  def index
    authorize User
    # Only executes if current_user.admin? || current_user.analyst?
  end
end
```

**Verify in Console**
```bash
rails console
admin = User.admin.first    # Get admin user
puts admin.inspect
puts admin.admin?           # => true
```

---

### 5. Subscription Model ✅

**Check User-Subscription Association**
```bash
rails console
user = User.first
user.subscription                    # => Subscription record
user.subscription.plan              # => :free (default)
user.subscription.status            # => :active
user.subscription.premium?          # => false
```

**Create Premium Subscription**
```bash
user.subscription.update(plan: :premium, status: :active)
user.subscription.premium?          # => true
```

---

### 6. Company & Sector Models ✅

**View Seeded Companies**
```bash
rails console
companies = Company.all
puts "Total companies: #{companies.count}"  # => 15+

# Find by sector
financial = Sector.find_by(name: "Financial Services")
gtco = Company.find_by(ticker_symbol: "GTCO")
puts "GTCO: #{gtco.name}, Sector: #{gtco.sector.name}"
puts "Current Price: #{gtco.current_price}"
puts "PE Ratio: #{gtco.pe_ratio}"
puts "Dividend Yield: #{gtco.dividend_yield}"
```

**View in Web UI**
- Navigate: http://localhost:3000/companies
- Should see table of 15+ companies with ticker, sector, price, etc.
- Click on a company → detailed view with all fields

---

### 7. Stock Prices & Historical Data ✅

**Create Historical Stock Price Record**
```bash
rails console
company = Company.find_by(ticker_symbol: "GTCO")
company.stock_prices.create!(
  open: 44.50,
  close: 45.50,
  high: 46.00,
  low: 44.00,
  volume: 1_000_000,
  recorded_at: Time.current
)

company.stock_prices.count  # => 1
```

---

### 8. Market Events ✅

**Create Event**
```bash
rails console
event = MarketEvent.create!(
  title: "Market Close",
  description: "NSE closes for the day",
  event_type: "close",
  event_date: Date.today
)
puts event.inspect
```

---

### 9. Remember-Me Functionality ✅

**Test in Browser**
- Login to http://localhost:3000/users/sign_in
- Check "Remember me"
- Close browser
- Return to site → Should still be logged in (cookie persists)

---

### 10. Email Verification ✅

**In Development**
- Check `tmp/letter_opener` folder for intercepted emails
- Or set Devise mailer in `config/initializers/devise.rb`:
```ruby
config.mailer_sender = 'noreply@stiip.ng'
```

---

## 🔍 Debugging Commands

### View All Users
```bash
rails console
User.all.each { |u| puts "#{u.email} | Role: #{u.role} | Confirmed: #{u.confirmed?}" }
```

### View All Companies by Sector
```bash
rails console
Sector.all.each do |sector|
  puts "#{sector.name}: #{sector.companies.count} companies"
end
```

### Check Subscription Status
```bash
rails console
User.all.each { |u| puts "#{u.email} | Plan: #{u.subscription.plan}" }
```

### Database Stats
```bash
rails console
puts "Users: #{User.count}"
puts "Companies: #{Company.count}"
puts "Sectors: #{Sector.count}"
puts "Subscriptions: #{Subscription.count}"
puts "Stock Prices: #{StockPrice.count}"
```

---

## ✅ All Tests Pass When

1. ✅ Database seeds successfully (no errors)
2. ✅ User can register and confirm email
3. ✅ User can login with credentials
4. ✅ Free user cannot access /admin (redirects)
5. ✅ Admin user can access /admin (loads dashboard)
6. ✅ Subscription associated with each user
7. ✅ 15+ companies seeded and visible
8. ✅ Companies show in web UI with all fields
9. ✅ Stock prices can be created and queried
10. ✅ Remember-me cookie persists login

---

## Next: Phase 2 Ready

Once Phase 1 is verified, move to:
- **Phase 2**: Stock Data Ingestion Architecture (CSV imports, providers)
- **Phase 2b**: Background Jobs (Sidekiq, scheduled syncing)

