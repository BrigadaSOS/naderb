require "rails_helper"

RSpec.describe ScheduledMessage, type: :model do
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

    it "requires a schedule" do
      message = build(:scheduled_message, schedule: nil)
      expect(message).not_to be_valid
      expect(message.errors[:schedule]).to be_present
    end

    it "requires a channel ID" do
      message = build(:scheduled_message, channel_id: nil)
      expect(message).not_to be_valid
      expect(message.errors[:channel_id]).to be_present
    end

    it "requires a consumer_type" do
      message = build(:scheduled_message, consumer_type: nil)
      expect(message).not_to be_valid
      expect(message.errors[:consumer_type]).to be_present
    end

    it "requires a timezone" do
      message = build(:scheduled_message, timezone: nil)
      expect(message).not_to be_valid
      expect(message.errors[:timezone]).to be_present
    end

    it "enforces unique names" do
      existing = create(:scheduled_message)
      duplicate = build(:scheduled_message, name: existing.name)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("has already been taken")
    end

    it "validates schedule syntax" do
      message = build(:scheduled_message, schedule: "invalid schedule")
      expect(message).not_to be_valid
      expect(message.errors[:schedule]).to be_present
    end
  end

  describe "scopes" do
    let!(:enabled_message) { create(:scheduled_message, enabled: true) }
    let!(:disabled_message) { create(:scheduled_message, enabled: false) }

    it "has an active scope that filters enabled messages" do
      expect(ScheduledMessage.active).to include(enabled_message)
      expect(ScheduledMessage.active).not_to include(disabled_message)
    end

    describe ".due" do
      let!(:past_due_message) { create(:scheduled_message, next_run_at: 1.hour.ago) }
      let!(:future_message) { create(:scheduled_message, next_run_at: 1.hour.from_now) }
      let!(:disabled_past_due) { create(:scheduled_message, enabled: false, next_run_at: 1.hour.ago) }

      it "returns only active messages that are due" do
        due_messages = ScheduledMessage.due
        expect(due_messages).to include(past_due_message)
        expect(due_messages).not_to include(future_message)
        expect(due_messages).not_to include(disabled_past_due)
      end
    end
  end

  describe "#calculate_next_run_at" do
    let(:message) { build(:scheduled_message, timezone: "America/Mexico_City") }

    it "calculates next run for daily schedule" do
      message.schedule = "every day at 8am"
      from_time = Time.zone.parse("2025-01-15 10:00:00 UTC")
      next_run = message.calculate_next_run_at(from_time)

      # Should be next day at 8am Mexico City time (which is 8am - 6h = 2pm UTC)
      expect(next_run).to be > from_time
      expect(next_run.hour).to eq(14) # 8am CST = 2pm UTC
    end

    it "calculates next run for hourly schedule" do
      message.schedule = "every hour"
      from_time = Time.zone.parse("2025-01-15 10:30:00 UTC")
      next_run = message.calculate_next_run_at(from_time)

      expect(next_run).to be > from_time
      expect(next_run).to be < from_time + 2.hours
    end

    it "calculates next run for every minute schedule" do
      message.schedule = "every minute"
      from_time = Time.zone.parse("2025-01-15 10:30:45 UTC")
      next_run = message.calculate_next_run_at(from_time)

      expect(next_run).to be > from_time
      expect(next_run).to be < from_time + 2.minutes
    end

    it "calculates next run for every 5 minutes schedule" do
      message.schedule = "every 5 minutes"
      from_time = Time.zone.parse("2025-01-15 10:32:00 UTC")
      next_run = message.calculate_next_run_at(from_time)

      expect(next_run).to be > from_time
      expect(next_run).to be < from_time + 6.minutes
    end

    it "handles invalid schedule gracefully" do
      message.schedule = "invalid schedule"
      from_time = Time.current
      next_run = message.calculate_next_run_at(from_time)

      # Should default to 1 hour from now
      expect(next_run).to be_within(5.seconds).of(from_time + 1.hour)
    end
  end

  describe "callbacks" do
    let(:user) { create(:user) }

    describe "before_validation on create" do
      it "sets next_run_at when creating a new message" do
        message = build(:scheduled_message, schedule: "every day at 8am")
        expect(message.next_run_at).to be_nil

        message.save!
        expect(message.next_run_at).to be_present
        expect(message.next_run_at).to be > Time.current
      end
    end

    describe "after_save" do
      it "recalculates next_run_at when schedule changes" do
        message = create(:scheduled_message, schedule: "every day at 8am")
        original_next_run = message.next_run_at

        message.update!(schedule: "every day at 9am")
        expect(message.next_run_at).not_to eq(original_next_run)
      end

      it "recalculates next_run_at when timezone changes" do
        message = create(:scheduled_message, timezone: "America/Mexico_City")
        original_next_run = message.next_run_at

        message.update!(timezone: "America/New_York")
        expect(message.next_run_at).not_to eq(original_next_run)
      end

      it "does not recalculate next_run_at when other fields change" do
        message = create(:scheduled_message)
        original_next_run = message.next_run_at

        message.update!(description: "New description")
        expect(message.reload.next_run_at).to eq(original_next_run)
      end
    end
  end

  describe "#render_template" do
    let(:message) do
      build(:scheduled_message,
            template: "Message at <%= time %> on <%= date %>",
            timezone: "America/Mexico_City")
    end

    it "renders ERB template with time variables" do
      rendered = message.render_template
      expect(rendered).to include("Message at")
      expect(rendered).to match(/\d{2}:\d{2} (AM|PM)/)
    end

    it "renders template with custom locals" do
      message.template = "Hello <%= @name %>"
      rendered = message.render_template(name: "World")
      expect(rendered).to eq("Hello World")
    end
  end
end
