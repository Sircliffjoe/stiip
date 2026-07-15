module Authenticatable
  extend ActiveSupport::Concern

  included do
    include Pundit::Authorization

    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

    helper_method :premium_user?, :business_api_user?
  end

  private

  def require_admin!
    authenticate_user!
    unless current_user.admin_role? || current_user.analyst_role?
      flash[:alert] = "Access denied."
      redirect_to root_path
    end
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end

  def premium_user?
    current_access_policy.premium?
  end

  def business_api_user?
    current_access_policy.business_api?
  end
  
  def after_sign_in_path_for(resource)
    if resource.admin_role? || resource.analyst_role?
      admin_dashboard_path
    else
      dashboard_path
    end
  end
end
