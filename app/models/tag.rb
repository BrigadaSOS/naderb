class Tag < ApplicationRecord
  belongs_to :user

  before_validation :normalize_name

  validates :name, presence: true,
                   length: { maximum: 50 },
                   format: { with: /\A[a-zA-Z0-9_-]+\z/ },
                   uniqueness: { scope: :guild_id }
  validates :content, presence: true, length: { maximum: 2000 }

  attribute :id, :uuid_v7, default: -> { SecureRandom.uuid_v7 }

  scope :by_name, ->(name) { where("LOWER(name) = ?", name.downcase) }

  def self.find_by_name(name)
    by_name(name).first
  end

  def image_url?
    return false unless content.present?

    # Check if the content is a valid URL
    uri = URI.parse(content.strip)
    return false unless uri.scheme&.match?(/^https?$/)

    # Skip Discord media URLs as they don't resolve without proper referrer
    return false if discord_media_url?(uri)

    # More lenient: check for image extensions OR assume it could be an image
    # This handles dynamic image services like picsum.photos, imgur, etc.
    has_image_extension = uri.path.match?(/\.(jpe?g|png|gif|webp|bmp|svg)$/i)

    # If it has an extension, it must be an image extension
    has_extension = uri.path.match?(/\.[a-z0-9]+$/i)
    return false if has_extension && !has_image_extension

    # Otherwise, try to display it as an image (no extension or has image extension)
    true
  rescue URI::InvalidURIError
    false
  end

  def discord_media_url?(uri = nil)
    uri ||= URI.parse(content.strip) rescue nil
    return false unless uri

    uri.host&.match?(/^(media|cdn)\.discordapp\.(net|com)$/i)
  rescue URI::InvalidURIError
    false
  end

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

  private

  def normalize_name
    self.name = name&.downcase&.strip
  end

  def is_editable_by(user)
    tag.user == user || user.admin_or_mod?
  end
end
