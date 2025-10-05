class TagService
  def initialize(user)
    @user = user
  end

  # Creates a new tag
  # @param tag_params [Hash] Tag attributes (name, content, etc.)
  # @return [Tag] The created tag
  # @raise [Tag::PermissionDenied] if user lacks create permission
  # @raise [Tag::ValidationFailed] if tag validations fail
  def create_tag(tag_params)
    tag = @user.tags.build(tag_params.merge(guild_id: Setting.discord_server_id))
    policy_for(tag).authorize_create!

    db_operation(tag, :create) {
      tag.save
    }
  end

  # Updates an existing tag
  # @param tag [Tag] The tag to update
  # @param tag_params [Hash] Tag attributes to update
  # @return [Tag] The updated tag
  # @raise [Tag::NotFound] if tag is nil
  # @raise [Tag::PermissionDenied] if user lacks update permission or can't change owner
  # @raise [Tag::ValidationFailed] if tag validations fail or new owner not found
  def update_tag(tag, tag_params)
    ensure_exists!(tag)
    policy_for(tag).authorize_update!

    update_params = prepare_update_params(tag, tag_params)
    db_operation(tag, :update) {
      tag.update(update_params)
    }
  end

  # Destroys a tag
  # @param tag [Tag] The tag to destroy
  # @return [Tag] The destroyed tag
  # @raise [Tag::NotFound] if tag is nil
  # @raise [Tag::PermissionDenied] if user lacks destroy permission
  # @raise [Tag::ValidationFailed] if destruction fails
  def destroy_tag(tag)
    ensure_exists!(tag)
    policy_for(tag).authorize_destroy!

    db_operation(tag, :destroy) {
      tag.destroy
    }
  end

  private

  def policy_for(tag)
    TagPolicy.new(@user, tag)
  end

  def ensure_exists!(tag, name = nil)
    unless tag
      # Try to provide a meaningful name for the error message
      tag_name = name || tag&.name || "unknown"
      raise Tag::NotFound.new(tag_name)
    end
  end

  def prepare_update_params(tag, tag_params)
    discord_uid = tag_params["discord_uid"]

    # We fetch the new user from the discord_uid
    if discord_uid.present?
      policy_for(tag).authorize_change_owner!

      new_owner = User.find_by(discord_uid: discord_uid)
      unless new_owner
        tag.errors.add(:base, I18n.t("activerecord.errors.models.tag.attributes.discord_uid.not_found",
                                    discord_uid: discord_uid))
        raise Tag::ValidationFailed.new(tag)
      end

      tag_params.except("discord_uid").merge(user: new_owner)
    else
      tag_params
    end
  end

  # Unified logging and error handling for DB operations
  def db_operation(tag, operation)
    raise ArgumentError, "Block code required for db_operation" unless block_given?
    success = yield

    if success
      Rails.logger.info "Tag '#{tag.name}' #{operation}d successfully by user #{@user.id}"
      tag
    else
      Rails.logger.error "Failed to #{operation} tag: #{tag.errors.full_messages.join(', ')}"
        raise Tag::ValidationFailed.new(tag)
    end
  rescue ActiveRecord::ActiveRecordError => e
    Rails.logger.error "Database error during tag #{operation}: #{e.message}"
      raise
  end
end
