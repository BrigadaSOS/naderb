class Dashboard::Admin::DataController < ApplicationController
  include WebAuthorization
  before_action :authenticate_user!
  before_action :admin_required!

  def inspect
    @table_name = params[:table_name]

    # Validate table exists and is safe to query
    unless valid_table?(@table_name)
      @error_message = "Invalid table name"
      render partial: "error", locals: { message: @error_message }, layout: false
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

      # Get paginated data - convert binary UUIDs to strings
      raw_records = ApplicationRecord.connection.execute("SELECT * FROM #{@table_name} LIMIT #{per_page} OFFSET #{offset}")
      @records = raw_records.map do |record|
        record.transform_values do |value|
          # Convert binary data to hex string for UUIDs
          if value.is_a?(String) && value.encoding == Encoding::ASCII_8BIT && value.length == 16
            value.unpack1("H*").scan(/.{8}|.{4}/).join("-")
          else
            value
          end
        end
      end

      # Calculate pagination info
      @current_page = page
      @total_pages = (@total_count.to_f / per_page).ceil
      @has_next = @current_page < @total_pages
      @has_prev = @current_page > 1

      render partial: "table_inspect", layout: false
    rescue => e
      Rails.logger.error "Database error inspecting #{@table_name}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      @error_message = "Database error: #{e.message}"
      render partial: "error", locals: { message: @error_message }, layout: false
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

