require "rails_helper"

RSpec.describe "Dividends", type: :request do
  let!(:sector) { Sector.create!(name: "Financial Services") }
  let!(:company) { Company.create!(name: "GTCO PLC", ticker_symbol: "GTCO", sector: sector, current_price: 100) }
  let!(:premium_user) { User.create!(email: "premium-dividends@example.com", password: "password", first_name: "Premium", last_name: "User", confirmed_at: Time.current, role: :premium) }

  before do
    Dividend.create!(company: company, amount: 2, year: 2025, qualification_date: 1.year.ago.to_date, payment_date: 11.months.ago.to_date)
    Dividend.create!(company: company, amount: 3, year: Date.current.year + 1, qualification_date: 1.month.from_now.to_date, payment_date: 2.months.from_now.to_date, interim: true)
  end

  it "splits historical and upcoming dividends for signed-in users" do
    sign_in premium_user

    get dividends_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Historical Dividends")
    expect(response.body).to include("Upcoming Dividends")
    expect(response.body).to include("Highest Latest Yield")
    expect(response.body).to include("Past payouts imported from EODHD or entered manually by admins.")
    expect(response.body).to include("tab=upcoming")
  end

  it "switches to upcoming dividends through a real tab link" do
    sign_in premium_user

    get dividends_path(tab: "upcoming")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Upcoming Dividends")
    expect(response.body).to include("Expected Payment")
    expect(response.body).to include("border-navy-700 text-navy-700")
  end

  it "paginates historical dividends with a load more link" do
    sign_in premium_user

    30.times do |index|
      Dividend.create!(
        company: company,
        amount: index + 1,
        year: 1990 + index,
        qualification_date: (index + 2).years.ago.to_date,
        payment_date: (index + 2).years.ago.to_date + 1.week,
        interim: index.even?
      )
    end

    get dividends_path

    expect(response.body).to include("Load more")
    expect(response.body).to include("25 of 31")
    expect(response.body).to include("historical_limit=50")
  end

  it "shows a login prompt to guests" do
    get dividends_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Log in to view dividend details")
    expect(response.body).not_to include("Highest Latest Yield")
  end
end
