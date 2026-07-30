class Admin::UsersController < Admin::ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :confirm]

  def index
    @users = User.includes(:subscription).order(created_at: :desc)
    if params[:query].present?
      q = "%#{params[:query]}%"
      @users = @users.where("email ILIKE ? OR first_name ILIKE ? OR last_name ILIKE ?", q, q, q)
    end
    if params[:role].present?
      @users = @users.where(role: params[:role])
    end
  end

  def show
    @subscription = @user.subscription
    @watchlists = @user.watchlists.includes(:companies)
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params.except(:subscription_plan, :confirm_user))
    @user.role = user_params[:role].presence || :free
    if params[:user][:confirm_user] == "1"
      @user.confirmed_at ||= Time.current
    end

    if @user.save
      if user_params[:subscription_plan].present?
        sub = @user.subscription || @user.build_subscription
        sub.update!(plan: user_params[:subscription_plan], status: :active, starts_at: Time.current)
      end
      redirect_to admin_users_path, notice: "User #{@user.email} created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    update_params = user_params.except(:subscription_plan, :confirm_user)
    if update_params[:password].blank?
      update_params = update_params.except(:password, :password_confirmation)
    end

    if @user.update(update_params)
      if params[:user][:confirm_user] == "1" && @user.confirmed_at.nil?
        @user.update_column(:confirmed_at, Time.current)
      end

      if user_params[:subscription_plan].present?
        sub = @user.subscription || @user.build_subscription
        sub.update!(plan: user_params[:subscription_plan], status: :active, starts_at: Time.current)
      end

      redirect_to admin_user_path(@user), notice: "User #{@user.email} updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def confirm
    if @user.confirmed?
      redirect_back fallback_location: admin_user_path(@user), notice: "User #{@user.email} is already confirmed."
    elsif @user.confirm
      redirect_back fallback_location: admin_user_path(@user), notice: "User #{@user.email} has been confirmed successfully."
    else
      redirect_back fallback_location: admin_user_path(@user), alert: "Unable to confirm user #{@user.email}."
    end
  end

  def destroy
    email = @user.email
    if @user == current_user
      redirect_to admin_users_path, alert: "You cannot delete your own admin account."
    else
      @user.destroy
      redirect_to admin_users_path, notice: "User #{email} deleted."
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(
      :first_name, :last_name, :email, :phone,
      :password, :password_confirmation, :role,
      :subscription_plan, :confirm_user
    )
  end
end
