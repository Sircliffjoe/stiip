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
    expect(response.body).to include("Future announced qualification and payment dates")
  end

  it "shows a login prompt to guests" do
    get dividends_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Log in to view dividend details")
    expect(response.body).not_to include("Highest Latest Yield")
  end
end
