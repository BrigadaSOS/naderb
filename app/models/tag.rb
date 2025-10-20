class Tag < ApplicationRecord
  belongs_to :user
  has_one_attached :image

  before_validation :normalize_name

  validates :name, presence: true,
                   length: { maximum: 50 },
                   format: { with: /\A[a-zA-Z0-9_-]+\z/ },
                   uniqueness: { scope: :guild_id }
  validates :content, length: { maximum: 2000 }, allow_blank: true
  validate :must_have_content_or_image, on: [ :create, :update ]

  attribute :id, :uuid_v7, default: -> { SecureRandom.uuid_v7 }

  scope :by_name, ->(name) { where("LOWER(name) = ?", name.downcase) }

  after_commit :queue_image_download, on: [ :create, :update ]

  def self.find_by_name(name)
    by_name(name).first
  end

  def content_is_image_url?
    return false if content.blank? || image.attached?

    trimmed = content.strip
    TagImageService.valid_image_url?(trimmed) && trimmed == content.strip
  end

  def discord_cdn_url?
    discord_cdn_url.present?
  end

  private

  def normalize_name
    self.name = name&.downcase&.strip
  end

  def must_have_content_or_image
    return if destroyed? || marked_for_destruction?

    has_content = content.present?
    has_url = discord_cdn_url.present?
    has_image = image.attached? && !image.attachment&.marked_for_destruction?

    unless has_content || has_image || has_url
      errors.add(:base, I18n.t("activerecord.errors.models.tag.must_have_content_or_image"))
    end
  end

  def queue_image_download
    return unless !image.attached? && (discord_cdn_url.present? || content_is_image_url?)
    Rails.logger.info "Queueing image download for tag #{name} (#{id})"

    url = discord_cdn_url || content.strip

    # Do this in a better way
    update_column(:content, nil) if content_is_image_url?

    update_column(:original_image_url, url)

    service = TagImageService.new(self)
    service.download_from_url(url, background: false)

  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "Tag #{id} not found: #{e.message}"

  rescue => e
    Rails.logger.error "Failed to queue image download for tag #{id}: #{e.message}"
  end
end
