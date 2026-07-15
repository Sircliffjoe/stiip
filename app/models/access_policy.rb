class AccessPolicy
  FREE_WATCHLIST_LIMIT = 1
  FREE_WATCHLIST_ITEM_LIMIT = 5
  FREE_PRICE_HISTORY_DAYS = 30

  attr_reader :user

  def initialize(user)
    @user = user
  end

  def guest?
    user.blank?
  end

  def signed_in?
    user.present?
  end

  def free?
    signed_in? && user.free_role?
  end

  def premium?
    signed_in? && (user.premium_role? || business_api? || analyst_or_admin?)
  end

  def business_api?
    signed_in? && (user.business_api_role? || user.admin_role?)
  end

  def analyst_or_admin?
    signed_in? && (user.analyst_role? || user.admin_role?)
  end

  def can_view_company_details?
    signed_in?
  end

  def can_view_full_price_history?
    premium?
  end

  def can_use_screener?
    premium?
  end

  def can_use_advanced_dividends?
    premium?
  end

  def can_export_data?
    premium?
  end

  def can_manage_api_keys?
    business_api?
  end

  def can_use_api?
    business_api?
  end

  def can_create_watchlist?
    return false if guest?
    return true if premium?

    user.watchlists.count < FREE_WATCHLIST_LIMIT
  end

  def can_add_watchlist_item?
    return false if guest?
    return true if premium?

    user.watchlist_items.count < FREE_WATCHLIST_ITEM_LIMIT
  end

  def price_history_start_date
    return nil if can_view_full_price_history?

    FREE_PRICE_HISTORY_DAYS.days.ago.to_date
  end
end
