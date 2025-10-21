require "rails_helper"

describe BirthdayCheckerService do
  describe "#check_and_send_birthday_notifications" do
    let(:today) { Date.new(2025, 1, 15) }
    let(:service) { BirthdayCheckerService.new }

    before do
      # Mock Time.current to return a consistent date
      allow(Time).to receive(:current).and_return(today.to_time.in_time_zone("America/Mexico_City"))
    end

    context "when there are users with birthdays today" do
      let(:user_with_birthday) { create(:user, birthday_month: 1, birthday_day: 15) }
      let(:scheduled_message) do
        create(:scheduled_message,
               schedule_type: "birthday",
               schedule_month: 1,
               schedule_day: 15,
               enabled: true)
      end

      it "creates a sent notification for each active message" do
        expect {
          service.check_and_send_birthday_notifications
        }.to change(SentNotification, :count)
      end

      it "renders the message template with user variables" do
        service.check_and_send_birthday_notifications

        notification = SentNotification.last
        expect(notification.message_data).to include(user_with_birthday.name)
      end

      it "does not send duplicate messages on the same day" do
        service.check_and_send_birthday_notifications
        expect(SentNotification.count).to eq(1)

        # Try sending again
        service.check_and_send_birthday_notifications
        expect(SentNotification.count).to eq(1)
      end
    end

    context "when there are no users with birthdays today" do
      let(:user_no_birthday) { create(:user, birthday_month: 2, birthday_day: 20) }

      it "does not create any sent notifications" do
        expect {
          service.check_and_send_birthday_notifications
        }.not_to change(SentNotification, :count)
      end
    end

    context "when messages are disabled" do
      let(:user_with_birthday) { create(:user, birthday_month: 1, birthday_day: 15) }
      let(:scheduled_message) do
        create(:scheduled_message,
               schedule_type: "birthday",
               schedule_month: 1,
               schedule_day: 15,
               enabled: false)
      end

      it "does not send disabled messages" do
        expect {
          service.check_and_send_birthday_notifications
        }.not_to change(SentNotification, :count)
      end
    end
  end

  describe "template rendering" do
    it "correctly renders template variables" do
      user = build(:user, birthday_month: 5, birthday_day: 20)
      message = build(:scheduled_message,
                      template: "Happy birthday {name}! {display_name} was born on {month}/{day}.",
                      schedule_month: 5,
                      schedule_day: 20)

      rendered = message.render_for_user(user)
      expect(rendered).to include(user.name)
      expect(rendered).to include("5/20")
    end
  end
end
