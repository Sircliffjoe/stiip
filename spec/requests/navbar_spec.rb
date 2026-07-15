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

  it "renders a mobile admin menu inside the admin layout" do
    admin = User.create!(
      email: "admin-menu@example.com",
      password: "password123",
      first_name: "Admin",
      last_name: "Menu",
      confirmed_at: Time.current,
      role: :admin
    )
    sign_in admin

    get admin_dashboard_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('aria-label="Open admin menu"')
    expect(response.body).to include("Admin Console")
    expect(response.body).to include("/admin/users")
    expect(response.body).to include("/admin/data_imports")
    expect(response.body).to include("&larr; Back to App")
  end
end
