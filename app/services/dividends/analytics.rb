module Dividends
  class Analytics
    def initialize(dividends)
      @dividends = dividends
    end

    def summary
      rows = grouped_company_rows

      {
        companies_count: rows.length,
        records_count: dividends.size,
        total_declared: dividends.sum { |dividend| dividend.amount.to_d },
        average_yield: average(rows.filter_map { |row| row[:latest_yield_percent] }),
        top_yields: rows.select { |row| row[:latest_yield_percent].present? }.sort_by { |row| -row[:latest_yield_percent] }.first(5),
        strongest_growth: rows.select { |row| row[:growth_percent].present? }.sort_by { |row| -row[:growth_percent] }.first(5),
        most_consistent: rows.sort_by { |row| [-row[:years_paid], row[:company].ticker_symbol] }.first(5)
      }
    end

    private

    attr_reader :dividends

    def grouped_company_rows
      dividends.group_by(&:company).filter_map do |company, company_dividends|
        sorted = company_dividends.sort_by { |dividend| dividend.qualification_date || dividend.payment_date || Date.new(dividend.year, 1, 1) }
        yearly_totals = sorted.group_by(&:year).transform_values { |rows| rows.sum { |dividend| dividend.amount.to_d } }
        latest_dividend = sorted.last
        latest_total = yearly_totals[latest_dividend.year]
        first_year, first_total = yearly_totals.min_by { |year, _amount| year }
        _latest_year, latest_year_total = yearly_totals.max_by { |year, _amount| year }

        {
          company: company,
          latest_dividend: latest_dividend,
          latest_total: latest_total,
          latest_yield_percent: yield_percent(company, latest_total),
          years_paid: yearly_totals.keys.compact.uniq.count,
          records_count: company_dividends.count,
          growth_percent: growth_percent(first_total, latest_year_total, first_year, latest_dividend.year)
        }
      end
    end

    def yield_percent(company, annual_dividend)
      price = company.latest_price.to_d
      return nil unless price.positive? && annual_dividend.present?

      ((annual_dividend.to_d / price) * 100).round(2)
    end

    def growth_percent(first_total, latest_total, first_year, latest_year)
      return nil unless first_total.to_d.positive?
      return nil if first_year.blank? || latest_year.blank? || first_year == latest_year

      (((latest_total.to_d - first_total.to_d) / first_total.to_d) * 100).round(2)
    end

    def average(values)
      return nil if values.blank?

      (values.sum { |value| value.to_d } / values.length).round(2)
    end
  end
end
