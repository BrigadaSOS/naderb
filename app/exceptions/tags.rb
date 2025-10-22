module Tags
  class Error < StandardError; end

  class PermissionDenied < Error
    def initialize(message = nil)
      super(message || I18n.t("tags.errors.permission_denied"))
    end
  end

  class ValidationFailed < Error
    attr_reader :record

    def initialize(record)
      @record = record
      errors = record.errors.full_messages.join(", ")
      super(I18n.t("tags.errors.validation_failed", errors: errors))
    end
  end

  class NotFound < Error
    def initialize(name)
      super(I18n.t("tags.errors.not_found", name: name))
    end
  end
end
