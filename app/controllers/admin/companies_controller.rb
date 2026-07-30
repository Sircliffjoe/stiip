class Admin::CompaniesController < Admin::ApplicationController
  before_action :set_company, only: [:show, :edit, :update, :destroy]

  def index
    @companies = Company.includes(:sector).order(name: :asc)
  end

  def show
  end

  def new
    @company = Company.new
    @sectors = Sector.order(:name)
  end

  def create
    @company = Company.new(company_params)

    if @company.save
      notice = "Company '#{@company.name}' created successfully."
      price_sync = sync_created_company_price(@company)
      notice = "#{notice} #{price_sync}" if price_sync.present?

      redirect_to admin_companies_path, notice: notice
    else
      @sectors = Sector.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @sectors = Sector.order(:name)
  end

  def update
    if @company.update(company_params)
      redirect_to admin_companies_path, notice: "Company '#{@company.name}' updated successfully."
    else
      @sectors = Sector.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @company.name
    @company.destroy
    redirect_to admin_companies_path, notice: "Company '#{name}' deleted."
  end

  private

  def set_company
    @company = Company.find(params[:id])
  end

  def company_params
    params.require(:company).permit(
      :name, :ticker_symbol, :sector_id, :description,
      :market_cap, :pe_ratio, :current_price, :opening_price, :closing_price,
      :high_52_week, :low_52_week, :dividend_yield, :shares_outstanding,
      :website, :logo_url, :logo, :investor_relations_url, :founded_year, :listed
    )
  end

  def sync_created_company_price(company)
    return unless company.listed?
    return if ENV["NGN_MARKET_KEY"].blank? || ENV["NGX_PULSE_KEY"].blank?

    result = DataIngestion::SyncCoordinator.new(provider: :market).sync_company_price(company.ticker_symbol)
    return "Latest market price synced." if result[:success] && result[:count].positive?

    "Price sync skipped: #{result[:error] || 'no quote returned'}."
  rescue StandardError => e
    Rails.logger.warn("[Admin::CompaniesController] Market price sync failed for #{company.ticker_symbol}: #{e.message}")
    "Price sync skipped."
  end
end
