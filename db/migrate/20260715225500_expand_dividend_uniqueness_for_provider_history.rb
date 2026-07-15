class ExpandDividendUniquenessForProviderHistory < ActiveRecord::Migration[8.0]
  OLD_INDEX = "index_dividends_on_company_id_and_year_and_interim"
  NEW_INDEX = "index_dividends_on_company_year_type_dates_amount"

  def change
    remove_index :dividends, name: OLD_INDEX

    add_index :dividends,
      [:company_id, :year, :interim, :qualification_date, :payment_date, :amount],
      unique: true,
      name: NEW_INDEX
  end
end
