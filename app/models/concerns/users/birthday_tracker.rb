module Users
  module BirthdayTracker
    extend ActiveSupport::Concern

    included do
      validates :birthday_month, inclusion: { in: 1..12, message: "must be between 1 and 12" }, allow_nil: true
      validates :birthday_day, inclusion: { in: 1..31, message: "must be between 1 and 31" }, allow_nil: true
      validate :birthday_month_and_day_together
    end

    def birthday?
      birthday_month.present? && birthday_day.present?
    end

    def birthday_today?(date = Time.current)
      return false unless birthday?
      date.month == birthday_month && date.day == birthday_day
    end

    private

    def birthday_month_and_day_together
      if (birthday_month.present? && birthday_day.blank?) || (birthday_month.blank? && birthday_day.present?)
        errors.add(:base, "Both birthday month and day must be provided together")
      end
    end
  end
end
