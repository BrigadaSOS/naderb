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

    render "index"
  end

  def new
    @tag = Tag.new

    respond_to do |format|
      format.html do
        @tags = Tag.all.order(created_at: :desc)
        @modal_open = true
        @new_tag = @tag
        render "index"
      end

      format.turbo_stream do
        render partial: "form", locals: { tag: @tag, title: "Create New Tag", submit_text: "Create Tag" }
      end
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
        turbo_stream.replace("tags_container", partial: "tags_list", locals: { tags: Tag.all.order(created_at: :desc) }),
        toast_success("Tag created successfully.")
      ]
    end
  end

  def update
    with_tag_service do |service|
      service.update_tag(@tag, tag_params)

      render turbo_stream: [
        turbo_stream.replace("tags_container", partial: "tags_list", locals: { tags: Tag.all.order(created_at: :desc) }),
        toast_success("Tag updated successfully.")
      ]
    end
  end

  def destroy
    with_tag_service do |serivce|
      service.destroy_tag(@tag)

      render turbo_stream: [
        turbo_stream.replace("tags_container", partial: "tags_list", locals: { tags: Tag.all.order(created_at: :desc) }),
        toast_success("Tag deleted successfully.")
      ]
    end
  end

  private

  def tag_params
    if current_user.admin_or_mod?(impersonated_roles: impersonated_roles)
      params.require(:tag).permit(:name, :content, :discord_uid)
    else
      params.require(:tag).permit(:name, :content)
    end
  end

  def set_tag
    @tag = Tag.find_by(id: params[:id])

    unless @tag
      redirect_to dashboard_server_tags_path, alert: "Tag not found"
    end
  end

  def require_create_permission!
    unless can_create_tag?
      render turbo_stream: toast_error("You need a trusted role to create tags"), status: :forbidden
    end
  end

  def require_edit_permission!
    unless can_edit_tag?(@tag)
      # For turbo frame requests, redirect within the frame
      if turbo_frame_request?
        redirect_to dashboard_server_tag_path(@tag), status: :see_other
      else
        redirect_to dashboard_server_tags_path, alert: "You don't have permission to edit this tag"
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
      render turbo_stream: toast_error("Database error, please try again"), status: :service_unavailable

    rescue => e
      render turbo_stream: toast_error("Unexpected error, please try again"), status: :service_unavailable
      Rails.logger.error "Unexpected error via bot: #{e.message}}"
    end
  end

  def render_tag_form(tag)
    read_only = !can_edit_tag?(tag)

    if turbo_frame_request?
      locals = {
        tag: tag,
        title: read_only ? "View Tag" : "Edit Tag",
        read_only: read_only
      }
      locals[:submit_text] = "Update Tag" unless read_only

      render partial: "form", locals: locals
    else
      @tags = Tag.all.order(created_at: :desc)
      @modal_open = true
      @edit_tag = tag
      @tag_read_only = read_only
      render "index"
    end
  end
end
