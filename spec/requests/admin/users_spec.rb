require 'rails_helper'

RSpec.describe "Admin::Users", type: :request do
  let(:admin_user) do
    User.create!(
      email: "admin-user-crud@example.com",
      password: "password123",
      first_name: "Admin",
      last_name: "Super",
      role: :admin,
      confirmed_at: Time.current
    )
  end

  let!(:target_user) do
    User.create!(
      email: "regular@example.com",
      password: "password123",
      first_name: "John",
      last_name: "Doe",
      role: :free,
      confirmed_at: Time.current
    )
  end

  before do
    sign_in admin_user
  end

  describe "GET /admin/users" do
    it "lists users" do
      get "/admin/users"
      expect(response).to have_http_status(:success)
      expect(response.body).to include("regular@example.com")
    end
  end

  describe "GET /admin/users/:id" do
    it "shows user details" do
      get "/admin/users/#{target_user.id}"
      expect(response).to have_http_status(:success)
      expect(response.body).to include("John")
    end
  end

  describe "POST /admin/users" do
    it "creates a new user with specified role and plan" do
      expect {
        post "/admin/users", params: {
          user: {
            first_name: "Alice",
            last_name: "Smith",
            email: "alice@example.com",
            password: "password123",
            password_confirmation: "password123",
            role: "premium",
            subscription_plan: "premium",
            confirm_user: "1"
          }
        }
      }.to change(User, :count).by(1)

      new_user = User.find_by(email: "alice@example.com")
      expect(new_user).to be_present
      expect(new_user.role).to eq("premium")
      expect(new_user.subscription.plan).to eq("premium")
      expect(response).to redirect_to(admin_users_path)
    end
  end

  describe "PATCH /admin/users/:id" do
    it "updates user details, role, and subscription" do
      patch "/admin/users/#{target_user.id}", params: {
        user: {
          first_name: "Johnny",
          last_name: "Doe",
          email: "regular@example.com",
          role: "analyst",
          subscription_plan: "business_api"
        }
      }

      target_user.reload
      expect(target_user.first_name).to eq("Johnny")
      expect(target_user.role).to eq("analyst")
      expect(target_user.subscription.plan).to eq("business_api")
      expect(response).to redirect_to(admin_user_path(target_user))
    end
  end

  describe "PATCH /admin/users/:id/confirm" do
    let!(:unconfirmed_user) do
      User.create!(
        email: "unconfirmed@example.com",
        password: "password123",
        first_name: "Pending",
        last_name: "User",
        role: :free
      )
    end

    it "confirms the unconfirmed user" do
      expect(unconfirmed_user.confirmed?).to be false
      patch "/admin/users/#{unconfirmed_user.id}/confirm"
      unconfirmed_user.reload
      expect(unconfirmed_user.confirmed?).to be true
      expect(response).to redirect_to(admin_user_path(unconfirmed_user))
    end
  end

  describe "DELETE /admin/users/:id" do
    it "deletes a user" do
      expect {
        delete "/admin/users/#{target_user.id}"
      }.to change(User, :count).by(-1)

      expect(response).to redirect_to(admin_users_path)
    end
  end
end
