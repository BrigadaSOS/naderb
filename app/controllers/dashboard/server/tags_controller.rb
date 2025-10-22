class Dashboard::Server::TagsController < ApplicationController
  include ErrorHandler

  before_action :authenticate_user!
  before_action :set_tags, only: [ :index, :new, :edit ]
  before_action :set_tag, only: [ :show, :edit, :update, :destroy ]
  before_action :require_create_permission!, only: [ :new, :create ]
  before_action :require_edit_permission!, only: [ :edit, :update, :destroy ]

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
    result = handle_tag_errors { tag_service.create_tag(tag_params) }

    if result.success?
      flash[:success] = t(".success")
      redirect_to dashboard_server_tags_path, status: :see_other
    else
      handle_error_result(result, :new)
    end
  end

  def update
    result = handle_tag_errors { tag_service.update_tag(@tag, tag_params) }

    if result.success?
      flash[:success] = t(".success")
      redirect_to dashboard_server_tags_path(search: params[:search]), status: :see_other
    else
      handle_error_result(result, :edit)
    end
  end

  def destroy
    result = handle_tag_errors { tag_service.destroy_tag(@tag) }

    if result.success?
      flash[:success] = t(".success")
      redirect_to dashboard_server_tags_path(search: params[:search]), status: :see_other
    else
      handle_error_result(result, :index)
    end
  end

  private

  def tag_params
    permitted = params.require("tag").permit("name", "content", "discord_uid", "image", "remove_image")
    permitted["_remove_image"] = permitted["remove_image"] == "true" if permitted["remove_image"].present?

    # Exclude UI-only params
    permitted.except("remove_image")
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
    @tag_service ||= Tags::TagService.new(current_user)
  end

  def handle_error_result(result, render_template)
    error = result.error

    case error[:type]
    when :permission_denied
      flash[:error] = error[:message]
      redirect_to dashboard_server_tags_path, status: :forbidden
    when :validation_failed
      @tag = error[:record]
      set_tags
      render render_template, status: :unprocessable_entity
    when :not_found
      flash[:error] = error[:message]
      redirect_to dashboard_server_tags_path
    when :database_error, :unexpected_error
      flash[:error] = t("errors.database")
      redirect_to dashboard_server_tags_path, status: :service_unavailable
    else
      flash[:error] = error[:message] || t("errors.generic")
      redirect_to dashboard_server_tags_path
    end
  end
end
