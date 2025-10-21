class BirthdayCheckerJob < ApplicationJob
  queue_as :default

  # Check for birthdays and send notifications
  def perform
    result = BirthdayCheckerService.new.check_and_send_birthday_notifications

    if result[:success]
      Rails.logger.info "BirthdayCheckerJob completed successfully. Sent #{result[:notifications_sent]} notifications"
    else
      Rails.logger.error "BirthdayCheckerJob failed: #{result[:error]}"
    end
  end
end
