class User < ApplicationRecord
  include Users::DiscordAuthenticatable
  include Users::RoleChecker
  include Users::BirthdayTracker

  # Include default devise modules. Others available are:
  devise :database_authenticatable, :trackable, :omniauthable, omniauth_providers: [ :discord ]

  attribute :id, :uuid_v7, default: -> { SecureRandom.uuid_v7 }

  has_many :tags, dependent: :destroy
  has_many :scheduled_messages, foreign_key: :created_by_id, dependent: :destroy

  validates :locale, inclusion: { in: -> { I18n.available_locales.map(&:to_s) }, allow_nil: true }

  def name
    display_name.presence || username || email || "User #{id}"
  end
end
