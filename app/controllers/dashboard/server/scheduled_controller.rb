class Dashboard::Server::ScheduledController < ApplicationController
  include WebAuthorization
  before_action :authenticate_user!
  before_action :admin_or_moderator_required!
  before_action :set_scheduled_message, only: [:show, :edit, :update, :destroy, :toggle_enabled, :test_execute, :executions]

  def index
    @scheduled_messages = ScheduledMessage.all.order(created_at: :desc)
  end

  def show
    @executions = @scheduled_message.executions.order(executed_at: :desc)
  end

  def new
    @scheduled_message = ScheduledMessage.new(
      enabled: true,
      consumer_type: "discord",
      timezone: "America/Mexico_City",
      schedule: "every day at 8am"
    )
  end

  def create
    @scheduled_message = ScheduledMessage.new(scheduled_message_params)
    @scheduled_message.created_by = current_user

    if @scheduled_message.save
      redirect_to dashboard_server_scheduled_path(@scheduled_message), notice: "Scheduled message created successfully"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @scheduled_message.update(scheduled_message_params)
      redirect_to dashboard_server_scheduled_path(@scheduled_message), notice: "Scheduled message updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @scheduled_message.destroy
    redirect_to dashboard_server_scheduled_index_path, notice: "Scheduled message deleted successfully"
  end

  def toggle_enabled
    @scheduled_message.update(enabled: !@scheduled_message.enabled?)
    redirect_to dashboard_server_scheduled_path(@scheduled_message), notice: "Scheduled message #{@scheduled_message.enabled? ? 'enabled' : 'disabled'} successfully"
  end

  # Test execute a message manually
  def test_execute
    executor = ScheduledMessageExecutorService.new
    result = executor.execute_message(@scheduled_message)

    respond_to do |format|
      if result[:status] == "success"
        format.html { redirect_to dashboard_server_scheduled_path(@scheduled_message), notice: "Test message sent successfully!" }
        format.json { render json: { success: true, message: "Test message sent successfully!", result: result } }
      elsif result[:status] == "skipped"
        format.html { redirect_to dashboard_server_scheduled_path(@scheduled_message), notice: "Message skipped: #{result[:delivery_result][:reason]}" }
        format.json { render json: { success: true, skipped: true, message: "Message skipped: #{result[:delivery_result][:reason]}", result: result } }
      else
        error_msg = result[:delivery_result][:details][:error] || result[:delivery_result][:details][:message] || "Unknown error"
        format.html { redirect_to dashboard_server_scheduled_path(@scheduled_message), alert: "Message execution failed: #{error_msg}" }
        format.json { render json: { success: false, error: error_msg, result: result }, status: :unprocessable_entity }
      end
    end
  end

  # View execution history for this message
  def executions
    @executions = @scheduled_message.executions.order(executed_at: :desc).page(params[:page]).per(20)
  end

  # Preview the rendered template
  def preview
    @preview_message = ScheduledMessage.new(scheduled_message_params)

    if @preview_message.valid?
      # Get preview data based on query type
      preview_locals = if @preview_message.data_query.present?
        DataQueryService.new.execute(
          @preview_message.data_query,
          date: Time.current,
          timezone: @preview_message.timezone
        )
      else
        {}
      end

      @rendered_preview = @preview_message.render_template(preview_locals)
      render json: { success: true, preview: @rendered_preview }
    else
      render json: { success: false, errors: @preview_message.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # Fetch Discord channels for the guild
  def channels
    channels = Rails.cache.fetch("discord_guild_channels", expires_in: 1.hour) do
      DiscordBotApiService.new.fetch_guild_channels
    end

    render json: { success: true, channels: channels }
  rescue => e
    Rails.logger.error "Error fetching channels: #{e.message}"
    render json: { success: false, error: e.message }, status: :internal_server_error
  end

  # Get metadata for a specific data query type
  def query_variables
    query_type = params[:query_type]

    if query_type.blank?
      render json: { success: false, error: "query_type parameter required" }, status: :bad_request
      return
    end

    metadata = DataQueryService.query_metadata(query_type)

    if metadata
      render json: { success: true, metadata: metadata }
    else
      render json: { success: false, error: "Unknown query type" }, status: :not_found
    end
  rescue => e
    Rails.logger.error "Error fetching query variables: #{e.message}"
    render json: { success: false, error: e.message }, status: :internal_server_error
  end

  private

  def set_scheduled_message
    @scheduled_message = ScheduledMessage.find(params[:id])
  end

  def scheduled_message_params
    params.require(:scheduled_message).permit(
      :name,
      :description,
      :template,
      :schedule,
      :data_query,
      :consumer_type,
      :timezone,
      :enabled,
      :channel_id,
      :conditions
    )
  end
end
