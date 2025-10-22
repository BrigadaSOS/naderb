class TagPolicy
  attr_reader :user, :tag

  def initialize(user, tag)
    @user = user
    @tag = tag
  end

  def can_show?
    true
  end

  def can_create?
    return false unless user

    user.trusted_user? || user.admin_or_mod?
  end

  def can_update?
    editable?
  end

  def can_destroy?
    editable?
  end

  def can_change_owner?
    user.admin_or_mod?
  end

  def authorize_create!
    raise Tags::PermissionDenied, I18n.t("tag_policy.errors.create") unless can_create?
  end

  def authorize_update!
    raise Tags::PermissionDenied, I18n.t("tag_policy.errors.update") unless can_update?
  end

  def authorize_destroy!
    raise Tags::PermissionDenied, I18n.t("tag_policy.errors.destroy") unless can_destroy?
  end

  def authorize_change_owner!
    raise Tags::PermissionDenied, I18n.t("tag_policy.errors.change_owner") unless can_change_owner?
  end

  private

  def editable?
    return false unless user && tag

    owned_by_user? || user.admin_or_mod?
  end

  def owned_by_user?
    tag.user_id == user.id
  end
end
