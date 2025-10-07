# Sync Discord settings from credentials to database
if Rails.application.credentials.discord.present?
  Setting.sync_from_credentials!
  puts "✓ Discord settings synced from credentials"
end

return unless Rails.env.development?

require 'faker'

guild_id = "999888777"

# Get or create a user to assign tags to
user = User.first_or_create!(
  email: "seed_user@example.com",
  discord_uid: "123456789"
) do |u|
  u.username = "seed_user"
  u.provider = "discord"
  u.password = Faker::Internet.password(min_length: 8, max_length: 20)
  u.display_name = Faker::Internet.username(specifier: 5..12)
  u.profile_image_url = "https://picsum.photos/200/200?random=3"
  u.locale = I18n.default_locale.to_s
  u.active = true
end

puts "Using user: #{user.email}"

# Create diverse sample tags with Faker
sample_tags = [
  { name: "short", content: Faker::Lorem.sentence },
  { name: "long", content: Faker::Lorem.paragraph(sentence_count: 5) },
  { name: "hipster", content: Faker::Hipster.paragraph },
  { name: "cat", content: "https://picsum.photos/id/234/500/400" },
  { name: "nature", content: "https://picsum.photos/id/69/500/400" },
  { name: "url", content: Faker::Internet.url }
]

created_count = 0
sample_tags.each do |tag_data|
  Tag.find_or_create_by!(name: tag_data[:name], guild_id: guild_id) do |t|
    t.content = tag_data[:content]
    t.user = user
    created_count += 1
  end
end

puts "Created #{created_count} new tags" if created_count > 0
puts "Seeding complete!"
