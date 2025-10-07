module OmniauthMock
  def setup_omniauth_discord_mock(custom_attributes = {})
    OmniAuth.config.test_mode = true

    base_auth = {
      provider: 'discord',
      uid: Faker::Number.number(digits: 18).to_s,
      info: {
        name: Faker::Internet.username,
        email: Faker::Internet.email,
        image: Faker::Avatar.image
      },
      credentials: {
        token: Faker::Alphanumeric.alphanumeric(number: 30),
        refresh_token: Faker::Alphanumeric.alphanumeric(number: 30),
        expires_at: 1.week.from_now.to_i
      },
      extra: {
        raw_info: {
          global_name: Faker::Name.name
        }
      }
    }

    if custom_attributes.any?
      base_auth[:uid] = custom_attributes[:uid] if custom_attributes[:uid]
      base_auth[:info].merge!(custom_attributes[:info]) if custom_attributes[:info]
      base_auth[:credentials].merge!(custom_attributes[:credentials]) if custom_attributes[:credentials]
      base_auth[:extra][:raw_info].merge!(custom_attributes[:raw_info]) if custom_attributes[:raw_info]
    end

    OmniAuth.config.mock_auth[:discord] = OmniAuth::AuthHash.new(base_auth)
  end

  def setup_omniauth_failure(strategy: :discord, error: :invalid_credentials)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[strategy] = error
  end

  def discord_auth_hash
    OmniAuth.config.mock_auth[:discord]
  end

  def teardown_omniauth_mock
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:discord] = nil
  end
end

RSpec.configure do |config|
  config.include OmniauthMock, type: :system
  config.include OmniauthMock, type: :request
end
