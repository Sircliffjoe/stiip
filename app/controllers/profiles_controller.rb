class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @watchlists_count = current_user.watchlists.count
    @notifications_count = current_user.notifications.unread.count
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    attributes = profile_params.to_h
    attributes.except!("password", "password_confirmation") if attributes["password"].blank?

    if @user.update(attributes)
      redirect_to profile_path, notice: "Settings updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:first_name, :last_name, :phone, :email, :password, :password_confirmation)
  end
end
