class Tag < ApplicationRecord
  belongs_to :user

  validates :name, presence: true,
                   length: { maximum: 50 },
                   format: { with: /\A[a-zA-Z0-9_-]+\z/ },
                   uniqueness: { scope: :guild_id }
  validates :content, presence: true, length: { maximum: 2000 }

  scope :by_name, ->(name) { where("LOWER(name) = ?", name.downcase) }

  before_validation :normalize_name

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
end
