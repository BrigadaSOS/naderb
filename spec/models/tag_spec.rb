require 'rails_helper'

RSpec.describe Tag, type: :model do
  let(:user) { create(:user) }
  let(:guild_id) { "999888777" }

  around do |example|
    I18n.with_locale(:en) { example.run }
  end

  describe 'associations' do
    it 'belongs to user' do
      expect(Tag.reflect_on_association(:user).macro).to eq(:belongs_to)
    end

    it 'has one attached image' do
      tag = create(:tag)
      expect(tag).to respond_to(:image)
      tag.image.attach(
        io: File.open(Rails.root.join('spec', 'fixtures', 'test_image.png')),
        filename: 'test_image.png',
        content_type: 'image/png'
      )
      expect(tag.image).to be_attached
    end
  end

  describe 'validations' do
    describe 'name validation' do
      it 'requires a name' do
        tag = build(:tag, name: nil)
        expect(tag).not_to be_valid
        expect(tag.errors[:name]).to include("is required")
      end

      it 'validates name format' do
        tag = build(:tag, name: "invalid name!")
        expect(tag).not_to be_valid
        expect(tag.errors[:name]).to include("can only contain letters, numbers, underscores and hyphens")
      end

      it 'validates uniqueness within guild' do
        create(:tag, name: "test", guild_id: guild_id)
        tag = build(:tag, name: "test", guild_id: guild_id)
        expect(tag).not_to be_valid
        expect(tag.errors[:name]).to include("already exists in this server")
      end

      it 'allows same name in different guilds' do
        create(:tag, name: "test", guild_id: "123")
        tag = build(:tag, name: "test", guild_id: "456")
        expect(tag).to be_valid
      end

      it 'normalizes name to lowercase' do
        tag = create(:tag, name: "TestTag")
        expect(tag.name).to eq("testtag")
      end
    end

    describe 'content validation' do
      it 'allows blank content if image is attached' do
        tag = build(:tag, content: "")
        tag.image.attach(
          io: File.open(Rails.root.join('spec', 'fixtures', 'test_image.png')),
          filename: 'test_image.png',
          content_type: 'image/png'
        )
        expect(tag).to be_valid
      end

      it 'validates maximum length' do
        tag = build(:tag, content: "a" * 2001)
        expect(tag).not_to be_valid
        expect(tag.errors[:content]).to include("is too long (maximum 2000 characters)")
      end
    end

    describe 'must_have_content_or_image validation' do
      it 'is invalid without content and without image' do
        tag = build(:tag, content: "")
        expect(tag).not_to be_valid
        expect(tag.errors[:base]).to include("must have either content or an attached image")
      end

      it 'is valid with content and without image' do
        tag = build(:tag, content: "Some content")
        expect(tag).to be_valid
      end

      it 'is valid with image and without content' do
        tag = build(:tag, content: "")
        tag.image.attach(
          io: File.open(Rails.root.join('spec', 'fixtures', 'test_image.png')),
          filename: 'test_image.png',
          content_type: 'image/png'
        )
        expect(tag).to be_valid
      end

      it 'is valid with both content and image' do
        tag = build(:tag, content: "Some content")
        tag.image.attach(
          io: File.open(Rails.root.join('spec', 'fixtures', 'test_image.png')),
          filename: 'test_image.png',
          content_type: 'image/png'
        )
        expect(tag).to be_valid
      end
    end
  end

  describe '#content_is_url_only?' do
    it 'returns true when content is only a valid image URL' do
      tag = build(:tag, content: "https://example.com/image.jpg")
      expect(tag.content_is_url_only?).to be true
    end

    it 'returns false when content has URL plus additional text' do
      tag = build(:tag, content: "Check this out https://example.com/image.jpg")
      expect(tag.content_is_url_only?).to be false
    end

    it 'returns false when content has text plus URL' do
      tag = build(:tag, content: "https://example.com/image.jpg - amazing picture")
      expect(tag.content_is_url_only?).to be false
    end

    it 'returns false for non-URL content' do
      tag = build(:tag, content: "Just some text")
      expect(tag.content_is_url_only?).to be false
    end

    it 'returns false when tag already has an attached image' do
      tag = build(:tag, content: "https://example.com/image.jpg")
      tag.image.attach(
        io: File.open(Rails.root.join('spec', 'fixtures', 'test_image.png')),
        filename: 'test_image.png',
        content_type: 'image/png'
      )
      expect(tag.content_is_url_only?).to be false
    end

    it 'returns false for nil content' do
      tag = build(:tag, content: "temp")
      tag.content = nil
      expect(tag.content_is_url_only?).to be false
    end
  end

  describe '#image_url?' do
    it 'is an alias for content_is_url_only?' do
      tag = build(:tag, content: "https://example.com/image.jpg")
      expect(tag.image_url?).to eq(tag.content_is_url_only?)
    end
  end

  describe '#discord_cdn_url?' do
    it 'returns true when discord_cdn_url column is present' do
      tag = build(:tag, content: "Some text", discord_cdn_url: "https://cdn.discordapp.com/attachments/123/456/image.jpg")
      expect(tag.discord_cdn_url?).to be true
    end

    it 'returns false when discord_cdn_url column is blank' do
      tag = build(:tag, content: "Some text", discord_cdn_url: nil)
      expect(tag.discord_cdn_url?).to be false
    end

    it 'returns false when discord_cdn_url is empty string' do
      tag = build(:tag, content: "Some text", discord_cdn_url: "")
      expect(tag.discord_cdn_url?).to be false
    end
  end

  describe '.find_by_name' do
    it 'finds tag by case-insensitive name' do
      tag = create(:tag, name: "test")
      expect(Tag.find_by_name("TEST")).to eq(tag)
      expect(Tag.find_by_name("Test")).to eq(tag)
      expect(Tag.find_by_name("test")).to eq(tag)
    end
  end

  describe 'destroy' do
    it 'can destroy a tag with content' do
      tag = create(:tag, content: "Some content")
      expect { tag.destroy }.to change(Tag, :count).by(-1)
    end

    it 'can destroy a tag with only an image' do
      tag = build(:tag, content: "")
      tag.image.attach(
        io: File.open(Rails.root.join('spec', 'fixtures', 'test_image.png')),
        filename: 'test_image.png',
        content_type: 'image/png'
      )
      tag.save!
      expect { tag.destroy }.to change(Tag, :count).by(-1)
    end

    it 'can destroy a tag with both content and image' do
      tag = create(:tag, content: "Some content")
      tag.image.attach(
        io: File.open(Rails.root.join('spec', 'fixtures', 'test_image.png')),
        filename: 'test_image.png',
        content_type: 'image/png'
      )
      expect { tag.destroy }.to change(Tag, :count).by(-1)
    end
  end
end
