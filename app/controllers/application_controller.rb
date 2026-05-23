class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  include Authenticatable

  helper_method :premium_user?

  private

  def require_premium!
    unless premium_user?
      flash[:alert] = "This feature requires a Premium subscription."
      redirect_to pricing_path
    end
  end

  def premium_user?
    user_signed_in? && (current_user.premium? || current_user.admin?)
  end
end
