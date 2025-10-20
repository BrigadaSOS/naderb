require 'rails_helper'
require 'discordrb'

# Use this when implementing integration tests
# 3.4.6 :049 > tag = TagCommands.instance_variable_get(:@application_commands)[:tag].subcommands[:get].call("aaa")

RSpec.describe 'TagCommands Integration' do
  let(:user) { create(:user, discord_uid: '123456789') }
  let(:discord_user) { double('discord_user', id: user.discord_uid, username: 'testuser', global_name: 'Test User') }
  let(:event) do
    double('Discordrb::Events::ApplicationCommandEvent',
      user: discord_user,
      options: {}
    )
  end

  before do
    stub_const('Setting', double(discord_server_id: '999888777'))
    allow(event).to receive(:defer)
    allow(event).to receive(:edit_response)
  end
end
