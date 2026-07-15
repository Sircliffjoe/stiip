class Admin::RecordsController < Admin::ApplicationController
  MODEL_NAMES = %w[
    ApiKey
    AuditLog
    Company
    CompanyNews
    DataImportLog
    DataSource
    Dividend
    EducationalContent
    MarketEvent
    NewsArticle
    Notification
    Sector
    StockPrice
    Subscription
    Tag
    Tagging
    User
    Watchlist
    WatchlistItem
  ].freeze

  before_action :set_model_class, except: :index
  before_action :set_record, only: %i[show edit update destroy]

  def index
    @model_names = MODEL_NAMES
  end

  def model_index
    @records = @model_class.order(created_at: :desc).limit(100)
  rescue ActiveRecord::StatementInvalid
    @records = @model_class.limit(100)
  end

  def show
  end

  def new
    @record = @model_class.new
  end

  def create
    @record = @model_class.new(record_params)

    if @record.save
      redirect_to admin_record_path(model: model_param, id: @record.id), notice: "#{model_label} created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @record.update(record_params)
      redirect_to admin_record_path(model: model_param, id: @record.id), notice: "#{model_label} updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @record.destroy
    redirect_to admin_records_model_path(model: model_param), notice: "#{model_label} deleted."
  end

  helper_method :model_param, :model_label, :editable_columns, :display_value

  private

  def set_model_class
    @model_class = MODEL_NAMES.find { |name| name.underscore == params[:model].to_s }&.constantize
    raise ActiveRecord::RecordNotFound, "Unknown admin model" unless @model_class
  end

  def set_record
    @record = @model_class.find(params[:id])
  end

  def record_params
    params.require(:record).permit(editable_columns)
  end

  def editable_columns
    @model_class.column_names - %w[id created_at updated_at]
  end

  def model_param
    @model_class.model_name.singular
  end

  def model_label
    @model_class.model_name.human
  end

  def display_value(record, column)
    value = record.public_send(column)
    case value
    when ActiveSupport::TimeWithZone, Time, Date
      value.to_fs(:db)
    else
      value.inspect
    end
  end
end
