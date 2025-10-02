class TagsService
  def initialize(user)
    @user = user
  end

  def create_tag(tag_params)
    tag = @user.tags.build(tag_params.merge(guild_id: Setting.discord_server_id))

    with_error_handling(tag) do
      if tag.save
        Rails.logger.info "Tag '#{tag.name}' created successfully by user #{@user.id}"
        { success: true, tag: tag }
      else
        Rails.logger.error "Failed to create tag: #{tag.errors.full_messages.join(', ')}"
          { success: false, tag: tag }
      end
    end
  end

  def update_tag(tag, tag_params)
    with_error_handling(tag) do
      update_params = tag_params.except(:discord_uid)
      tag.assign_attributes(update_params)

      # Handle owner change if discord_uid is provided and user is admin/mod
      if tag_params[:discord_uid].present? && @user.discord_admin_or_mod?
        new_owner = User.find_by(discord_uid: tag_params[:discord_uid])
        unless new_owner
          tag.errors.add(
            :base,
            I18n.t("activerecord.errors.models.tag.attributes.discord_uid.not_found",
                   discord_uid: tag_params[:discord_uid])
          )
          return { success: false, tag: tag }
        end

        update_params[:user] = new_owner
      end

      if tag.update(update_params)
        Rails.logger.info "Tag '#{tag.name}' updated successfully by user #{@user.id}"
        { success: true, tag: tag }
      else
        Rails.logger.error "Failed to update tag: #{tag.errors.full_messages.join(', ')}"
          { success: false, tag: tag }
      end
    end
  end

  def destroy_tag(tag)
    with_error_handling(tag) do
      if tag.destroy
        Rails.logger.info "Tag '#{tag.name}' deleted successfully by user #{@user.id}"
        { success: true, tag: tag }
      else
        Rails.logger.error "Failed to delete tag: #{tag.errors.full_messages.join(', ')}"
          tag.errors.add(:base, "Failed to delete tag")
        { success: false, tag: tag }
      end
    end
  end

  private

  def with_error_handling(tag)
    begin
      yield
    rescue ActiveRecord::ActiveRecordError => e
      Rails.logger.error "Database error: #{e.message}"
        tag.errors.add(:base, "An unexpected error ocurred, please retry later")
      { success: false, tag: tag }
    rescue => e
      Rails.logger.error "Uncaught Exceptio: #{e.message}"
        tag.errors.add(:base, "An unexpected error ocurred, please retry later")
      { success: false, tag: tag }
    end
  end
end
