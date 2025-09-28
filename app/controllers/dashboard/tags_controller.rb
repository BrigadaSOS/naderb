class Dashboard::TagsController < ApplicationController
  include TurboFrameOnly

  before_action :authenticate_user!
  before_action :set_tag, only: [ :show, :edit, :update, :destroy ]
  before_action :check_edit_permissions, only: [ :update, :destroy ]

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

    if turbo_frame_request?
      render partial: "form", locals: { tag: @tag, title: "Create New Tag", submit_text: "Create Tag" }
    else
      # Regular request - render full page with modal open
      @tags = Tag.all.order(created_at: :desc)
      @modal_open = true
      @new_tag = @tag
      render "index"
    end
  end

  def show
    edit
  end

  def edit
    if turbo_frame_request?
      if can_edit_tag?(@tag)
        render partial: "form", locals: {
          tag: @tag,
          title: "Edit Tag",
          submit_text: "Update Tag"
        }
      else
        render partial: "form", locals: {
          tag: @tag,
          title: "View Tag",
          read_only: true
        }
      end
    else
      @tags = Tag.all.order(created_at: :desc)
      @modal_open = true
      @edit_tag = @tag
      render "index"
    end
  end

  def create
    result = TagsService.new(current_user).create_tag(tag_params)

    if result[:success]
      render_with_toast(
        "Tag created successfully.",
        type: :success,
        streams: [
          turbo_stream.replace("tags_container", partial: "tags_list", locals: { tags: Tag.all.order(created_at: :desc) })
        ]
      )
    else
      render partial: "form", locals: {
        tag: result[:tag], title: "Create New Tag", submit_text: "Create Tag"
      }
      response.status = :unprocessable_entity
    end
  end

  def update
    result = TagsService.new(current_user).update_tag(@tag, tag_params)

    if result[:success]
      render_with_toast(
        "Tag updated successfully.",
        type: :success,
        streams: [
          turbo_stream.replace("tags_container", partial: "tags_list", locals: { tags: Tag.all.order(created_at: :desc) })
        ]
      )
    else
      # Preserve the form state when there are errors
      render_edit_form(result[:tag])
      response.status = :unprocessable_entity
    end
  end

  def destroy
    result = TagsService.new(current_user).destroy_tag(@tag)

    if result[:success]
      render_with_toast(
        "Tag deleted successfully.",
        type: :success,
        streams: [
          turbo_stream.replace("tags_container", partial: "tags_list", locals: { tags: Tag.all.order(created_at: :desc) })
        ]
      )
    else
      # Preserve the form state when there are errors
      render_edit_form(@tag)
      response.status = :unprocessable_entity
    end
  end

  private


  def set_tag
    @tag = Tag.find_by(id: params[:id])

    unless @tag
      redirect_to dashboard_tags_path, alert: "Tag not found"
    end
  end

  def tag_params
    if current_user.admin_or_mod?
      params.require(:tag).permit(:name, :content, :discord_uid)
    else
      params.require(:tag).permit(:name, :content)
    end
  end

  def check_edit_permissions
    unless can_edit_tag?(@tag)
      render turbo_stream: toast_error("You do not have permission to edit this tag"), status: :forbidden
    end
  end

  def can_edit_tag?(tag)
    tag.user == current_user || current_user.admin_or_mod?
  end
  helper_method :can_edit_tag?

  def can_create_tag?
    # TODO: Check if the user has discord role to create tags
  end

  def render_edit_form(tag)
    if turbo_frame_request?
      if can_edit_tag?(tag)
        render partial: "form", locals: {
          tag: tag,
          title: "Edit Tag",
          submit_text: "Update Tag"
        }
      else
        render partial: "form", locals: {
          tag: tag,
          title: "View Tag",
          read_only: true
        }
      end
    else
      @tags = Tag.all.order(created_at: :desc)
      @modal_open = true
      @edit_tag = tag
      render "index"
    end
  end
end
