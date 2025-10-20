# Simple module to hold Tag exception classes
module TagExceptions
  class PermissionDenied < StandardError
    def initialize(message = nil)
      super(message || I18n.t("tags.errors.permission_denied"))
    end
  end

  class ValidationFailed < StandardError
    attr_reader :record

    def initialize(record)
      @record = record
      errors = record.errors.full_messages.join(", ")
      super(I18n.t("tags.errors.validation_failed", errors: errors))
    end
  end

  class NotFound < StandardError
    def initialize(name)
      super(I18n.t("tags.errors.not_found", name: name))
    end
  end
end
