class Tag < ApplicationRecord
  # Custom exceptions for tag operations
  class PermissionDenied < StandardError; end
  class ValidationFailed < StandardError
    attr_reader :record

    def initialize(record)
      @record = record
      super(record.errors.full_messages.join(", "))
    end
  end
  class NotFound < StandardError; end

  before_validation :normalize_name

  validates :name, presence: true,
                   length: { maximum: 50 },
                   format: { with: /\A[a-zA-Z0-9_-]+\z/ },
                   uniqueness: { scope: :guild_id }
  validates :content, presence: true, length: { maximum: 2000 }

  belongs_to :user

  # Use uuid v7
  attribute :id, :uuid_v7, default: -> { SecureRandom.uuid_v7 }

  scope :by_name, ->(name) { where("LOWER(name) = ?", name.downcase) }

  def self.find_by_name(name)
    by_name(name).first
  end

  def image_url?
    return false unless content.present?

    # Check if the content is a valid URL and has an image extension
    uri = URI.parse(content.strip)
    return false unless uri.scheme&.match?(/^https?$/)

    # Check for common image extensions
    uri.path.match?(/\.(jpe?g|png|gif|webp|bmp|svg)$/i)
  rescue URI::InvalidURIError
    false
  end

  private

  def normalize_name
    self.name = name&.downcase&.strip
  end

  def is_editable_by(user)
    tag.user == user || user.admin_or_mod?
  end
end
