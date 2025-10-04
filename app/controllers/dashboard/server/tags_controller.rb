class Dashboard::Server::TagsController < ApplicationController
  include Toastable

  before_action :authenticate_user!
  before_action :set_tag, only: [ :show, :edit, :update, :destroy ]
  before_action :tag_create_permission_required!, only: [ :new, :create ]
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
    render_tag_form(@tag, read_only: true)
  end


  def edit
    render_tag_form(@tag, read_only: false)
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
      render_tag_form(result[:tag])
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
      render_tag_form(@tag)
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
    if current_user.admin_or_mod?(impersonated_roles: impersonated_roles)
      params.require(:tag).permit(:name, :content, :discord_uid)
    else
      params.require(:tag).permit(:name, :content)
    end
  end


  def tag_create_permission_required!
    unless can_create_tag?
      render turbo_stream: toast_error("You need a trusted role to create tags"), status: :forbidden
    end
  end


  def can_create_tag?
    current_user.trusted_user?(impersonated_roles: impersonated_roles) || current_user.admin_or_mod?(impersonated_roles: impersonated_roles)
  end

  def can_edit_tag?(tag)
    (tag.user == current_user) || current_user.admin_or_mod?(impersonated_roles: impersonated_roles)
  end
  helper_method :can_edit_tag?

  def render_tag_form(tag, read_only: nil)
    if turbo_frame_request?
      # If read_only not specified, determine based on permissions
      read_only = !can_edit_tag?(tag) if read_only.nil?

      locals = {
        tag: tag,
        title: read_only ? "View Tag" : "Edit Tag",
        read_only: read_only
      }
      locals[:submit_text] = "Update Tag" unless read_only

      render partial: "form", locals: locals
    else
      # For full page loads, pass read_only state to the view
      read_only = !can_edit_tag?(tag) if read_only.nil?

      @tags = Tag.all.order(created_at: :desc)
      @modal_open = true
      @edit_tag = tag
      @tag_read_only = read_only
      render "index"
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
end
