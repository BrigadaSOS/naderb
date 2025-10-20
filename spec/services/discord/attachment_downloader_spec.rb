require 'rails_helper'

RSpec.describe Discord::AttachmentDownloader do
  describe '.parse_url' do
    it 'extracts metadata from Discord CDN URL' do
      url = 'https://cdn.discordapp.com/attachments/845568081761796096/1413310512636235826/image.png?ex=68bb777c&is=68ba25fc&hm=1b55c913944a8bc14a4db19f7cca431bc73b532b7c983307408122282888b4bd&'

      metadata = described_class.parse_url(url)

      expect(metadata[:discord_channel_id]).to eq('845568081761796096')
      expect(metadata[:discord_message_id]).to eq('1413310512636235826')
      expect(metadata[:filename]).to eq('image.png')
    end

    it 'returns empty hash for invalid URLs' do
      expect(described_class.parse_url('https://example.com/image.png')).to eq({})
    end
  end

  describe '.url_expired?' do
    it 'returns true for expired URLs' do
      # Create a URL with an expiration timestamp in the past (hex encoded Unix timestamp)
      past_timestamp = (Time.current - 2.hours).to_i.to_s(16)
      url = "https://cdn.discordapp.com/attachments/845568081761796096/1413310512636235826/image.png?ex=#{past_timestamp}&is=68ba25fc&hm=1b55c913944a8bc14a4db19f7cca431bc73b532b7c983307408122282888b4bd&"

      expect(described_class.url_expired?(url)).to be true
    end

    it 'returns true for URLs expiring soon (within 1 hour)' do
      # Create a URL with an expiration timestamp 30 minutes from now
      soon_timestamp = (Time.current + 30.minutes).to_i.to_s(16)
      url = "https://cdn.discordapp.com/attachments/845568081761796096/1413310512636235826/image.png?ex=#{soon_timestamp}&is=68ba25fc&hm=1b55c913944a8bc14a4db19f7cca431bc73b532b7c983307408122282888b4bd&"

      expect(described_class.url_expired?(url)).to be true
    end

    it 'returns false for URLs with future expiration (more than 1 hour away)' do
      # Create a URL with an expiration timestamp 2 hours from now
      future_timestamp = (Time.current + 2.hours).to_i.to_s(16)
      url = "https://cdn.discordapp.com/attachments/845568081761796096/1413310512636235826/image.png?ex=#{future_timestamp}&is=68ba25fc&hm=1b55c913944a8bc14a4db19f7cca431bc73b532b7c983307408122282888b4bd&"

      expect(described_class.url_expired?(url)).to be false
    end

    it 'returns false for URLs without expiration parameters' do
      url = 'https://cdn.discordapp.com/attachments/845568081761796096/1413310512636235826/image.png'

      expect(described_class.url_expired?(url)).to be false
    end

    it 'returns true for malformed URLs' do
      expect(described_class.url_expired?('not a valid url')).to be true
    end
  end
end
