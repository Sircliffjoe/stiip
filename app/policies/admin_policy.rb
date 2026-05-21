class AdminPolicy < Struct.new(:user, :admin)
  def index?
    user&.admin? || user&.analyst?
  end

  def manage?
    user&.admin?
  end
end
