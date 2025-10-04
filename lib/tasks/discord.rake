namespace :discord do
  desc "Sync all Discord server members to the database"
  task sync_members: :environment do
    require "httparty"

    puts "Starting Discord member sync..."
    puts ""
    puts "⚠️  IMPORTANT: This task requires the 'Server Members Intent' to be enabled"
    puts "   in the Discord Developer Portal for your bot application."
    puts "   Go to: https://discord.com/developers/applications"
    puts "   Select your application → Bot → Privileged Gateway Intents"
    puts "   Enable 'SERVER MEMBERS INTENT'"
    puts ""

    token = Setting.discord_bot_token
    server_id = Setting.discord_server_id

    if token.blank?
      puts "Error: Discord bot token not configured"
      exit 1
    end

    if server_id.blank?
      puts "Error: Discord server ID not configured"
      exit 1
    end

    begin
      base_url = "https://discord.com/api/v10"
      headers = {
        "Authorization" => "Bot #{token}",
        "User-Agent" => "DiscordBot (Nadeshikorb, 1.0)"
      }

      # First, get server info
      puts "Fetching server info..."
      server_response = HTTParty.get("#{base_url}/guilds/#{server_id}", headers: headers)

      unless server_response.success?
        puts "Error: Could not fetch server info: #{server_response.code} #{server_response.message}"
        exit 1
      end

      server_data = server_response.parsed_response
      puts "Connected to server: #{server_data['name']}"
      puts "Fetching members..."

      # Fetch members with pagination
      all_members = []
      after = nil
      limit = 1000 # Max allowed by Discord API

      loop do
        url = "#{base_url}/guilds/#{server_id}/members?limit=#{limit}"
        url += "&after=#{after}" if after

        response = HTTParty.get(url, headers: headers)

        unless response.success?
          puts "Error fetching members: #{response.code} #{response.message}"
          break
        end

        members = response.parsed_response
        break if members.empty?

        all_members.concat(members)
        puts "Fetched #{all_members.count} members so far..."

        # Check if there are more members
        if members.count < limit
          break
        else
          # Use the last member's ID for pagination
          after = members.last["user"]["id"]
        end

        # Rate limiting protection
        sleep 0.5
      end

      puts "Found #{all_members.count} total members"

      synced_count = 0
      updated_count = 0
      reactivated_count = 0
      failed_count = 0
      deactivated_count = 0

      # Track Discord UIDs of current members
      current_member_uids = []

      all_members.each do |member|
        begin
          user_data = member["user"]

          # Skip bots
          if user_data["bot"] == true
            puts "⊘ Skipping bot: #{user_data['username']} (#{user_data['id']})"
            next
          end

          discord_uid = user_data["id"]
          current_member_uids << discord_uid

          # Username is the raw Discord username (e.g., "dibad_")
          username = user_data["username"]
          # Display name is the server nickname or global display name (e.g., "Dav")
          display_name = member["nick"] || user_data["global_name"] || username
          joined_at = member["joined_at"] ? Time.parse(member["joined_at"]) : nil

          user = User.find_or_initialize_by(discord_uid: discord_uid)
          was_new_record = user.new_record?
          was_inactive = !was_new_record && !user.active?

          if was_new_record
            # New user - set all required fields
            user.assign_attributes(
              username: username,
              display_name: display_name,
              discord_joined_at: joined_at,
              provider: "discord_bot",
              password: Devise.friendly_token[0, 20],
              active: true
            )
          else
            # Existing user - update username, display_name, and ensure active
            user.assign_attributes(
              username: username,
              display_name: display_name,
              discord_joined_at: joined_at || user.discord_joined_at,
              active: true
            )
          end

          if user.save
            if was_new_record
              synced_count += 1
              puts "✓ Created user: #{display_name} (@#{username}) (#{discord_uid})"
            elsif was_inactive
              reactivated_count += 1
              puts "↑ Reactivated user: #{display_name} (@#{username}) (#{discord_uid})"
            else
              updated_count += 1
              puts "↻ Updated user: #{display_name} (@#{username}) (#{discord_uid})"
            end
          else
            failed_count += 1
            puts "✗ Failed to save user #{display_name} (@#{username}): #{user.errors.full_messages.join(', ')}"
          end
        rescue => e
          failed_count += 1
          puts "✗ Error processing member: #{e.message}"
        end
      end

      # Mark users who left the server as inactive
      puts "\nChecking for users who left the server..."
      users_who_left = User.where.not(discord_uid: current_member_uids).where(active: true)

      users_who_left.each do |user|
        user.update(active: false)
        puts "✗ Deactivated user who left: #{user.display_name || user.username} (@#{user.username}) (#{user.discord_uid})"
        deactivated_count += 1
      end

      puts "\n" + "=" * 50
      puts "Sync complete!"
      puts "New users created: #{synced_count}"
      puts "Existing users updated: #{updated_count}"
      puts "Users reactivated (rejoined): #{reactivated_count}"
      puts "Users deactivated (left server): #{deactivated_count}"
      puts "Failed: #{failed_count}"
      puts "Total users in database: #{User.count}"
      puts "Active users: #{User.where(active: true).count}"
      puts "Inactive users: #{User.where(active: false).count}"
      puts "Bot-created users: #{User.where(provider: 'discord_bot').count}"
      puts "OAuth users: #{User.where(provider: 'discord').count}"
      puts "=" * 50
    rescue => e
      puts "Error during sync: #{e.message}"
      puts e.backtrace.join("\n")
      exit 1
    end
  end
end
