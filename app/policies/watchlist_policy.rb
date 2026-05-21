class WatchlistPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present? && record.user_id == user.id
  end

  def create?
    user.present?
  end

  def update?
    user.present? && record.user_id == user.id
  end

  def destroy?
    user.present? && record.user_id == user.id
  end
end
