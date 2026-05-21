class NewsArticlePolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    user&.admin? || user&.analyst?
  end

  def update?
    user&.admin? || user&.analyst?
  end

  def destroy?
    user&.admin?
  end
end
