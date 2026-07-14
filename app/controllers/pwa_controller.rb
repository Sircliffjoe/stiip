class PwaController < ApplicationController
  skip_before_action :authenticate_user!, raise: false
  skip_forgery_protection only: :service_worker

  def manifest
    render formats: :json
  end

  def service_worker
    response.headers["Service-Worker-Allowed"] = "/"
    render formats: :js, content_type: "application/javascript"
  end
end
