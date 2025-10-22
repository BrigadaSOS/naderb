# Unified error handling concern for tag operations
# Provides consistent error handling and response formatting across
# bot commands and web controllers
#
# Usage:
#   include ErrorHandler
#
#   result = handle_tag_errors do
#     service.create_tag(params)
#   end
#
#   if result.success?
#     # Handle success
#   else
#     # Format error response based on result.error
#   end
module ErrorHandler
  # Result object returned by error handler
  class Result
    attr_reader :success, :error, :data

    def initialize(success:, error: nil, data: nil)
      @success = success
      @error = error
      @data = data
    end

    def success? = @success
    def failure? = !@success
  end

  # Handle tag-related errors and return a Result object
  # @yield Block that performs the tag operation
  # @return [Result] Result object with success/error information
  def handle_tag_errors
    data = yield
    Result.new(success: true, data: data)
  rescue Tags::PermissionDenied => e
    Result.new(
      success: false,
      error: {
        type: :permission_denied,
        message: e.message
      }
    )
  rescue Tags::ValidationFailed => e
    Result.new(
      success: false,
      error: {
        type: :validation_failed,
        message: e.message,
        record: e.record
      }
    )
  rescue Tags::NotFound => e
    Result.new(
      success: false,
      error: {
        type: :not_found,
        message: e.message,
        tag_name: e.tag_name
      }
    )
  rescue ActiveRecord::RecordInvalid => e
    Result.new(
      success: false,
      error: {
        type: :invalid_record,
        message: e.message,
        record: e.record
      }
    )
  rescue ActiveRecord::ActiveRecordError => e
    Rails.logger.error("Database error: #{e.message}")
    Result.new(
      success: false,
      error: {
        type: :database_error,
        message: "Database error occurred"
      }
    )
  rescue => e
    Rails.logger.error("Unexpected error: #{e.message}\n#{e.backtrace.join("\n")}")
    Result.new(
      success: false,
      error: {
        type: :unexpected_error,
        message: "An unexpected error occurred"
      }
    )
  end
end
