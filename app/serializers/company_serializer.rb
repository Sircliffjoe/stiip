class CompanySerializer
  include JSONAPI::Serializer
  attributes :name, :ticker_symbol, :market_cap, :pe_ratio, :dividend_yield, :logo_url
  
  attribute :current_price do |object|
    object.latest_price
  end

  attribute :beginner_explanation do |object|
    object.pe_ratio_explanation
  end
end
