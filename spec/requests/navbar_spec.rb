require "rails_helper"

RSpec.describe "Navbar", type: :request do
  it "renders a mobile menu with public navigation and auth actions" do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('aria-label="Open menu"')
    expect(response.body).to include("/market")
    expect(response.body).to include("/dividends")
    expect(response.body).to include("/users/sign_in")
    expect(response.body).to include("/users/sign_up")
  end
end
