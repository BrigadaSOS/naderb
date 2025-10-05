class Dashboard::Server::TagsController < ApplicationController
  include Toastable

  before_action :authenticate_user!
  before_action :set_tag, only: [ :show, :edit, :update, :destroy ]
  before_action :require_create_permission!, only: [ :new, :create ]
  before_action :require_edit_permission!, only: [ :edit, :update, :destroy ]

  def index
    @tags = Tag.all

    if params[:search].present?
      @tags = @tags.where("LOWER(name) LIKE ?", "%#{params[:search].downcase}%")
    end

    @tags = @tags.order(created_at: :desc)
  end

  def new
    @tag = Tag.new
    @title = t(".title")
    @submit_text = t(".submit")

    if turbo_frame_request?
      render partial: "form", locals: { tag: @tag }
    else
      @tags = Tag.all.order(created_at: :desc)
      @tag_form_content = render_to_string(partial: "form", locals: { tag: @tag })
      render "index"
    end
  end

  def show
    render_tag_form(@tag)
  end

  def edit
    render_tag_form(@tag)
  end

  def create
    with_tag_service do |service|
      service.create_tag(tag_params)

      render turbo_stream: [
        turbo_stream.replace("tags_list", partial: "tags_list", locals: { tags: Tag.all.order(created_at: :desc) }),
        turbo_stream.update("tag_form", ""),
        toast_success(t(".success"))
      ]
    end
  end

  def update
    with_tag_service do |service|
      service.update_tag(@tag, tag_params)

      render turbo_stream: [
        turbo_stream.replace("tags_list", partial: "tags_list", locals: { tags: Tag.all.order(created_at: :desc) }),
        turbo_stream.update("tag_form", ""),
        toast_success(t(".success"))
      ]
    end
  end

  def destroy
    with_tag_service do |service|
      service.destroy_tag(@tag)

      render turbo_stream: [
        turbo_stream.replace("tags_list", partial: "tags_list", locals: { tags: Tag.all.order(created_at: :desc) }),
        turbo_stream.update("tag_form", ""),
        toast_success(t(".success"))
      ]
    end
  end

  private

  def tag_params
    params.require("tag").permit("name", "content", "discord_uid")
  end

  def set_tag
    @tag = Tag.find_by(id: params[:id])

    unless @tag
      redirect_to dashboard_server_tags_path, alert: t(".not_found")
    end
  end

  def require_create_permission!
    unless can_create_tag?
      render turbo_stream: toast_error(t(".forbidden")), status: :forbidden
    end
  end

  def require_edit_permission!
    unless can_edit_tag?(@tag)
      if turbo_frame_request?
        redirect_to dashboard_server_tag_path(@tag), status: :see_other
      else
        redirect_to dashboard_server_tags_path, alert: t(".forbidden")
      end
    end
  end

  def can_create_tag?
    TagPolicy.new(current_user, nil).can_create?
  end

  def can_edit_tag?(tag)
    TagPolicy.new(current_user, tag).can_update?
  end
  helper_method :can_edit_tag?

  def render_tag_form(tag)
    @read_only = !can_edit_tag?(tag)

    # Determine the correct translation scope based on tag state
    if tag.new_record?
      @title = t("dashboard.server.tags.new.title")
      @submit_text = t("dashboard.server.tags.new.submit")
    else
      @title = t(".title.#{@read_only ? 'show' : 'edit'}")
      @submit_text = @read_only ? nil : t(".submit")
    end

    if turbo_frame_request?
      render partial: "form", locals: { tag: tag }
    else
      # Full page load - render index with modal open
      @tags = Tag.all.order(created_at: :desc)
      @tag_form_content = render_to_string(partial: "form", locals: { tag: tag })
      render "index"
    end
  end

  def with_tag_service
    begin
      service = TagService.new(current_user)
      yield service

    rescue Tag::PermissionDenied => e
      render turbo_stream: toast_error(e.message), status: :forbidden

    rescue Tag::ValidationFailed => e
      render_tag_form(e.record)
      response.status = :unprocessable_entity

    rescue Tag::NotFound => e
      redirect_to dashboard_server_tags_path, alert: e.message

    rescue ActiveRecord::ActiveRecordError => e
      Rails.logger.error "Database error: #{e.message}"
        render turbo_stream: toast_error(t("errors.database")), status: :service_unavailable
    rescue => e
      Rails.logger.error "Unexpected error: #{e.message}\n#{e.backtrace.join("\n")}"
        render turbo_stream: toast_error(t("errors.unexpected")), status: :service_unavailable
    end
  end
end
