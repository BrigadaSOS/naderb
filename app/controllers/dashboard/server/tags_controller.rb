class Dashboard::Server::TagsController < ApplicationController
  include Toastable

  before_action :authenticate_user!
  before_action :set_tag, only: [ :show, :edit, :update, :destroy ]
  before_action :check_create_permissions, only: [ :new, :create ]
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
    render_edit_form(@tag)
  end


  def edit
    render_edit_form(@tag)
  end

  def create
    result = TagsService.new(current_user).create_tag(tag_params)

    if result[:success]
      render turbo_stream: [
        turbo_stream.replace("tags_container", partial: "tags_list", locals: { tags: Tag.all.order(created_at: :desc) }),
        toast_success("Tag created successfully.")
      ]
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
      render turbo_stream: [
        turbo_stream.replace("tags_container", partial: "tags_list", locals: { tags: Tag.all.order(created_at: :desc) }),
        toast_success("Tag updated successfully.")
      ]
    else
      render_edit_form(result[:tag])
      response.status = :unprocessable_entity
    end
  end

  def destroy
    result = TagsService.new(current_user).destroy_tag(@tag)

    if result[:success]
      render turbo_stream: [
        turbo_stream.replace("tags_container", partial: "tags_list", locals: { tags: Tag.all.order(created_at: :desc) }),
        toast_success("Tag deleted successfully.")
      ]
    else
      render_edit_form(@tag)
      response.status = :unprocessable_entity
    end
  end


  private


  def set_tag
    @tag = Tag.find_by(id: params[:id])

    unless @tag
      redirect_to dashboard_server_tags_path, alert: "Tag not found"
    end
  end

  def tag_params
    if current_user.discord_admin_or_mod?
      params.require(:tag).permit(:name, :content, :discord_uid)
    else
      params.require(:tag).permit(:name, :content)
    end
  end

  def check_create_permissions
    unless can_create_tag?
      render turbo_stream: toast_error("You need a trusted role to create tags"), status: :forbidden
    end
  end

  def check_edit_permissions
    unless can_edit_tag?(@tag)
      render turbo_stream: toast_error("You do not have permission to edit this tag"), status: :forbidden
    end
  end

  def can_create_tag?
    current_user.discord_trusted? || current_user.discord_admin_or_mod?
  end
  helper_method :can_create_tag?

  def can_edit_tag?(tag)
    # Owner can edit if they have trusted role, or admin/mod can always edit
    (tag.user == current_user && current_user.discord_trusted?) || current_user.discord_admin_or_mod?
  end
  helper_method :can_edit_tag?

  def render_edit_form(tag)
    if turbo_frame_request?
      read_only = true unless can_edit_tag?(@tag)

      locals = {
        tag: @tag,
        title: read_only ? "View Tag" : "Edit Tag"
      }
      locals[:submit_text] = "Update Tag" unless read_only
      locals[:read_only] = true if read_only

      render partial: "form", locals: locals
    else
      @tags = Tag.all.order(created_at: :desc)
      @modal_open = true
      @edit_tag = tag
      render "index"
    end
  end
end
