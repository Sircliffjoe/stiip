class ApiKeysController < ApplicationController
  before_action :authenticate_user!

  def index
    @api_keys = current_user.api_keys.order(created_at: :desc)
    @api_key = current_user.api_keys.build
  end

  def create
    unless current_access_policy.can_manage_api_keys?
      redirect_to api_keys_path, alert: "API keys require the Business/API plan."
      return
    end

    @api_key = current_user.api_keys.build(api_key_params)

    if @api_key.save
      @plain_token = @api_key.plain_token
      @api_keys = current_user.api_keys.order(created_at: :desc)
      flash.now[:notice] = "API key created. Copy it now; it will only be shown once."
      render :index, status: :created
    else
      @api_keys = current_user.api_keys.order(created_at: :desc)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    api_key = current_user.api_keys.find(params[:id])
    api_key.revoke!
    redirect_to api_keys_path, notice: "API key revoked."
  end

  private

  def api_key_params
    params.require(:api_key).permit(:name)
  end
end
