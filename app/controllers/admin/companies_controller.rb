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
      redirect_to admin_companies_path, notice: "Company '#{@company.name}' created successfully."
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
      :website, :investor_relations_url, :founded_year, :listed
    )
  end
end
