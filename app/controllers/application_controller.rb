class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  include Authenticatable

  helper_method :current_access_policy, :premium_user?, :business_api_user?

  private

  def current_access_policy
    @current_access_policy ||= AccessPolicy.new(user_signed_in? ? current_user : nil)
  end

  def require_premium!
    unless premium_user?
      flash[:alert] = "This feature requires a Premium subscription."
      redirect_to pricing_path
    end
  end

  def require_login_for_feature!
    return true if user_signed_in?

    flash[:alert] = "You must be logged in to access this information."
    redirect_to new_user_session_path
    false
  end

  def require_business_api!
    return true if business_api_user?

    flash[:alert] = "This feature requires the Business/API plan."
    redirect_to pricing_path
    false
  end

  def premium_user?
    current_access_policy.premium?
  end

  def business_api_user?
    current_access_policy.business_api?
  end
end
