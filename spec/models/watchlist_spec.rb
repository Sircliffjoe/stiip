require "rails_helper"

RSpec.describe Watchlist, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }
  end

  describe "associations" do
    it { should belong_to(:user) }
    it { should have_many(:watchlist_items).dependent(:destroy) }
    it { should have_many(:companies).through(:watchlist_items) }
  end
end
