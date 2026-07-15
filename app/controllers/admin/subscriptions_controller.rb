class Admin::SubscriptionsController < Admin::ApplicationController
  before_action :set_subscription, only: [:show, :edit, :update, :destroy]

  def index
    page = (params[:page] || 1).to_i
    per_page = 20
    offset = (page - 1) * per_page
    
    @subscriptions = Subscription.includes(:user).offset(offset).limit(per_page).order(created_at: :desc)
    @total_subscriptions = Subscription.count
    @current_page = page
    @per_page = per_page
    @total_pages = (@total_subscriptions.to_f / per_page).ceil
    
    @total_revenue = calculate_total_revenue
    @active_subscriptions = Subscription.where(status: :active).count
    @expired_subscriptions = Subscription.where(status: :expired).count
  end

  def show
  end

  def edit
  end

  def update
    if @subscription.update(subscription_params)
      @subscription.user.update!(role: @subscription.plan)
      redirect_to admin_subscription_path(@subscription), notice: "Subscription updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    user = @subscription.user
    @subscription.destroy!
    
    # Downgrade user to free
    user.update!(role: :free)
    
    Notification.create!(
      user: user,
      title: "Subscription Cancelled",
      body: "Your subscription has been cancelled by an administrator.",
      notification_type: "info"
    )
    
    redirect_to admin_subscriptions_path, notice: "Subscription cancelled and user downgraded to free."
  end

  private

  def set_subscription
    @subscription = Subscription.find(params[:id])
  end

  def subscription_params
    params.require(:subscription).permit(:status, :plan, :expires_at)
  end

  def calculate_total_revenue
    Subscription.where(status: :active, plan: :premium).count * 2500 +
      Subscription.where(status: :active, plan: :business_api).count * 25_000
  end
end
