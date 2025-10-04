class Dashboard::Admin::DataController < ApplicationController
  include WebAuthorization
  before_action :authenticate_user!
  before_action :admin_required!

  def inspect
    @table_name = params[:table_name]

    # Validate table exists and is safe to query
    unless valid_table?(@table_name)
      render json: { error: "Invalid table name" }, status: :bad_request
      return
    end

    # Get table data with pagination
    page = params[:page]&.to_i || 1
    per_page = 50
    offset = (page - 1) * per_page

    begin
      # Get column information
      @columns = ApplicationRecord.connection.columns(@table_name).map(&:name)

      # Get total count
      @total_count = ApplicationRecord.connection.execute("SELECT COUNT(*) FROM #{@table_name}").first.values.first

      # Get paginated data
      @records = ApplicationRecord.connection.execute("SELECT * FROM #{@table_name} LIMIT #{per_page} OFFSET #{offset}")

      # Calculate pagination info
      @current_page = page
      @total_pages = (@total_count.to_f / per_page).ceil
      @has_next = @current_page < @total_pages
      @has_prev = @current_page > 1

      respond_to do |format|
        format.json do
          render json: {
            table_name: @table_name,
            columns: @columns,
            records: @records.to_a,
            pagination: {
              current_page: @current_page,
              total_pages: @total_pages,
              total_count: @total_count,
              has_next: @has_next,
              has_prev: @has_prev
            }
          }
        end
        format.html { render partial: "table_inspect" }
      end
    rescue => e
      render json: { error: "Database error: #{e.message}" }, status: :internal_server_error
    end
  end

  private

  def valid_table?(table_name)
    return false if table_name.blank?

    # Only allow actual database tables, exclude Rails internal tables
    allowed_tables = ApplicationRecord.connection.tables.reject do |table|
      table.start_with?("ar_") || table == "schema_migrations"
    end

    allowed_tables.include?(table_name)
  end
end

