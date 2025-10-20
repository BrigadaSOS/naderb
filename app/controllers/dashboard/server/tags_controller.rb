class Dashboard::Server::TagsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_tags, only: [ :index, :new, :edit ]
  before_action :set_tag, only: [ :show, :edit, :update, :destroy ]
  before_action :require_create_permission!, only: [ :new, :create ]
  before_action :require_edit_permission!, only: [ :edit, :update, :destroy ]

  rescue_from TagExceptions::PermissionDenied, with: :handle_permission_denied
  rescue_from TagExceptions::ValidationFailed, with: :handle_validation_failed
  rescue_from TagExceptions::NotFound, with: :handle_not_found
  rescue_from ActiveRecord::ActiveRecordError, with: :handle_database_error

  def index
  end

  def new
    @tag = Tag.new
  end

  def show
  end

  def edit
  end

  def create
    tag_service.create_tag(tag_params)
    flash[:success] = t(".success")
    redirect_to dashboard_server_tags_path, status: :see_other
  end

  def update
    tag_service.update_tag(@tag, tag_params)
    flash[:success] = t(".success")
    redirect_to dashboard_server_tags_path(search: params[:search]), status: :see_other
  end

  def destroy
    tag_service.destroy_tag(@tag)
    flash[:success] = t(".success")
    redirect_to dashboard_server_tags_path(search: params[:search]), status: :see_other
  end

  private

  def tag_params
    permitted = params.require("tag").permit("name", "content", "discord_uid", "image", "input_mode", "remove_image")
    permitted["_remove_image"] = permitted["remove_image"] == "true" if permitted["remove_image"].present?

    # TODO: Can we remove input_mode from here?
    # UI-only params
    permitted.except("input_mode", "remove_image")
  end

  def set_tag
    @tag = Tag.find_by(id: params[:id])

    unless @tag
      redirect_to dashboard_server_tags_path, alert: t(".not_found")
    end
  end

  def require_create_permission!
    unless can_create_tag?
      redirect_to dashboard_server_tags_path, alert: t(".forbidden"), status: :forbidden
    end
  end

  def require_edit_permission!
    unless can_edit_tag?(@tag)
      redirect_to dashboard_server_tag_path(@tag), status: :see_other
    end
  end

  def set_tags
    @tags = Tag.all

    if params[:search].present?
      @tags = @tags.where("LOWER(name) LIKE ?", "%#{params[:search].downcase}%")
    end

    @tags = @tags.order(created_at: :desc)
  end

  def can_create_tag?
    TagPolicy.new(current_user, nil).can_create?
  end

  def can_edit_tag?(tag)
    TagPolicy.new(current_user, tag).can_update?
  end
  helper_method :can_edit_tag?

  def tag_service
    @tag_service ||= TagService.new(current_user)
  end

  def handle_permission_denied(exception)
    flash[:error] = exception.message
    redirect_to dashboard_server_tags_path, status: :forbidden
  end

  def handle_validation_failed(exception)
    @tag = exception.record
    set_tags

    template = case action_name
    when "create" then :new
    when "update" then :edit
    else action_name.to_sym
    end

    render template, status: :unprocessable_entity
  end

  def handle_not_found(exception)
    flash[:error] = exception.message
    redirect_to dashboard_server_tags_path
  end

  def handle_database_error(exception)
    Rails.logger.error "Database error: #{exception.message}"
    flash[:error] = t("errors.database")
    redirect_to dashboard_server_tags_path, status: :service_unavailable
  end
end
