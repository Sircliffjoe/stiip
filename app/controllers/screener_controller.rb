class ScreenerController < ApplicationController
  def index
    @locked_feature = !current_access_policy.can_use_screener?
    return if @locked_feature

    @sectors = Sector.order(:name)
    @companies = Company.includes(:sector)

    # Filter by search term
    if params[:search].present?
      @companies = @companies.search_by_term(params[:search])
    end

    # Filter by Country / Market
    if params[:market].present?
      case params[:market]
      when 'ngx'
        @companies = @companies.ngx
      when 'us'
        @companies = @companies.us
      end
    end

    # Filter by Sector
    if params[:sector_id].present?
      @companies = @companies.where(sector_id: params[:sector_id])
    end

    # Filter by Signal
    if params[:signal].present?
      @companies = @companies.where(signal: params[:signal])
    end

    # Filter by Dividend Yield Status
    if params[:dividend_status].present?
      case params[:dividend_status]
      when 'yielding'
        @companies = @companies.where("dividend_yield > 0")
      when 'non_yielding'
        @companies = @companies.where("dividend_yield = 0 OR dividend_yield IS NULL")
      end
    end

    # Filter by YTD Return
    if params[:ytd].present?
      case params[:ytd]
      when 'positive'
        @companies = @companies.where("ytd_return > 0")
      when 'high'
        @companies = @companies.where("ytd_return >= 15")
      when 'negative'
        @companies = @companies.where("ytd_return < 0")
      end
    end

    # Sorting
    sort_column = params[:sort] || 'name'
    sort_direction = params[:direction] || 'asc'
    
    # Sanitize sort fields
    allowed_sort = %w[name ticker_symbol current_price ytd_return dividend_yield revenue net_profit signal]
    sort_column = 'name' unless allowed_sort.include?(sort_column)
    sort_direction = 'asc' unless %w[asc desc].include?(sort_direction)

    @companies = @companies.order("#{sort_column} #{sort_direction}")
  end
end
