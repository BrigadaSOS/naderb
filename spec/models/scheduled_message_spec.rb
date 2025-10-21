require "rails_helper"

describe ScheduledMessage do
  describe "validations" do
    let(:user) { create(:user) }

    it "requires a name" do
      message = build(:scheduled_message, name: nil)
      expect(message).not_to be_valid
      expect(message.errors[:name]).to be_present
    end

    it "requires a template" do
      message = build(:scheduled_message, template: nil)
      expect(message).not_to be_valid
      expect(message.errors[:template]).to be_present
    end

    it "requires a schedule type" do
      message = build(:scheduled_message, schedule_type: nil)
      expect(message).not_to be_valid
      expect(message.errors[:schedule_type]).to be_present
    end

    it "requires a channel ID" do
      message = build(:scheduled_message, channel_id: nil)
      expect(message).not_to be_valid
      expect(message.errors[:channel_id]).to be_present
    end

    it "requires schedule_month and schedule_day for birthday type" do
      message = build(:scheduled_message, schedule_type: "birthday", schedule_month: nil, schedule_day: 15)
      expect(message).not_to be_valid
      expect(message.errors[:schedule_month]).to be_present
    end

    it "validates schedule_month is between 1-12" do
      message = build(:scheduled_message, schedule_month: 13)
      expect(message).not_to be_valid
    end

    it "validates schedule_day is between 1-31" do
      message = build(:scheduled_message, schedule_day: 32)
      expect(message).not_to be_valid
    end

    it "enforces unique names" do
      existing = create(:scheduled_message)
      duplicate = build(:scheduled_message, name: existing.name)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("has already been taken")
    end
  end

  describe "scopes" do
    let(:enabled_message) { create(:scheduled_message, enabled: true) }
    let(:disabled_message) { create(:scheduled_message, enabled: false) }

    it "has an active scope that filters enabled messages" do
      expect(ScheduledMessage.active).to include(enabled_message)
      expect(ScheduledMessage.active).not_to include(disabled_message)
    end

    it "has a for_birthday scope" do
      message = create(:scheduled_message, schedule_type: "birthday")
      expect(ScheduledMessage.for_birthday).to include(message)
    end

    it "has a for_today scope" do
      today_message = create(:scheduled_message, schedule_month: Date.today.month, schedule_day: Date.today.day)
      other_message = create(:scheduled_message, schedule_month: 6, schedule_day: 15)

      expect(ScheduledMessage.for_today).to include(today_message)
      expect(ScheduledMessage.for_today).not_to include(other_message)
    end
  end

  describe "#render_for_user" do
    let(:user) { build(:user, username: "testuser", display_name: "Test User") }
    let(:message) do
      build(:scheduled_message,
            template: "Happy birthday {name}! {username} was born on {month}/{day}.",
            schedule_month: 3,
            schedule_day: 15)
    end

    it "replaces template variables with user data" do
      rendered = message.render_for_user(user)
      expect(rendered).to include("Test User")
      expect(rendered).to include("testuser")
      expect(rendered).to include("3/15")
    end

    it "handles extra variables passed in" do
      rendered = message.render_for_user(user, years_old: 25)
      expect(rendered).to include(user.name)
    end
  end

  describe "#already_sent_today?" do
    let(:message) { create(:scheduled_message) }

    it "returns false if no notifications sent today" do
      expect(message.already_sent_today?).to be_falsey
    end

    it "returns true if a notification was sent today" do
      create(:sent_notification, scheduled_message: message, sent_at: Time.current)
      expect(message.already_sent_today?).to be_truthy
    end

    it "returns false if notification was sent yesterday" do
      create(:sent_notification, scheduled_message: message, sent_at: 1.day.ago)
      expect(message.already_sent_today?).to be_falsey
    end
  end
end
