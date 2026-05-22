require "rails_helper"

RSpec.describe Notification, type: :model do
  describe "validations" do
    it { should validate_presence_of(:title) }
  end

  describe "scopes" do
    it "separates read and unread notifications" do
      user = User.create!(
        first_name: "Ada",
        last_name: "Lagos",
        email: "ada@example.com",
        password: "password123",
        confirmed_at: Time.current
      )
      unread = described_class.create!(user: user, title: "Unread")
      read = described_class.create!(user: user, title: "Read", read_at: Time.current)

      expect(described_class.unread).to include(unread)
      expect(described_class.unread).not_to include(read)
      expect(described_class.read).to include(read)
    end
  end
end
