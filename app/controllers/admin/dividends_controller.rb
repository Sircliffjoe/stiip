class Admin::DividendsController < Admin::ApplicationController
  before_action :set_dividend, only: [:show, :edit, :update, :destroy]

  def index
    @dividends = Dividend.includes(:company).order(qualification_date: :desc)
  end

  def show
  end

  def new
    @dividend = Dividend.new(year: Date.current.year)
    @companies = Company.order(:name)
  end

  def create
    @dividend = Dividend.new(dividend_params)

    if @dividend.save
      redirect_to admin_dividends_path, notice: "Dividend for '#{@dividend.company.ticker_symbol}' created successfully."
    else
      @companies = Company.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @companies = Company.order(:name)
  end

  def update
    if @dividend.update(dividend_params)
      redirect_to admin_dividends_path, notice: "Dividend updated successfully."
    else
      @companies = Company.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @dividend.destroy
    redirect_to admin_dividends_path, notice: "Dividend deleted."
  end

  private

  def set_dividend
    @dividend = Dividend.find(params[:id])
  end

  def dividend_params
    params.require(:dividend).permit(
      :company_id, :amount, :currency, :qualification_date,
      :payment_date, :year, :interim, :status
    )
  end
end
