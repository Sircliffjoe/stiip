class AddFundamentalsToCompanies < ActiveRecord::Migration[8.0]
  def change
    add_column :companies, :country, :string, default: "NG"
    add_column :companies, :ytd_return, :decimal, precision: 8, scale: 2, default: 0.0
    add_column :companies, :revenue, :bigint
    add_column :companies, :net_profit, :bigint
    add_column :companies, :signal, :integer, default: 1
    add_column :companies, :ai_analysis_summary, :text
    add_column :companies, :ai_analysis_updated_at, :datetime
  end
end
