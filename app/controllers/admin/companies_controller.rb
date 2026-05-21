class Admin::CompaniesController < Admin::ApplicationController
  def index
    @companies = Company.all.order(name: :asc)
  end
end
