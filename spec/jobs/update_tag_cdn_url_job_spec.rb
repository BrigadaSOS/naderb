# frozen_string_literal: true

require "rails_helper"

RSpec.describe UpdateTagCdnUrlJob, type: :job do
  let(:user) { create(:user) }
  let(:tag) { create(:tag, user: user, content: "Some text") }
  let(:discord_cdn_url) { "https://cdn.discordapp.com/attachments/123456/789012/image.png" }

  describe "#perform" do
    context "when tag has no cached Discord CDN URL" do
      it "caches the Discord CDN URL" do
        described_class.perform_now(tag.id, discord_cdn_url)

        tag.reload
        expect(tag.discord_cdn_url).to eq(discord_cdn_url)
        expect(tag.content).to eq("Some text") # Content unchanged
      end
    end

    context "when tag has expired Discord CDN URL" do
      before do
        expired_url = "https://cdn.discordapp.com/attachments/123/456/image.png?ex=67000000&is=66fff000&hm=abc123"
        tag.update!(discord_cdn_url: expired_url)

        # Stub the expiration check to return true
        allow_any_instance_of(Tag).to receive(:discord_url_expired?).and_return(true)
      end

      it "updates with the new Discord CDN URL" do
        described_class.perform_now(tag.id, discord_cdn_url)

        tag.reload
        expect(tag.discord_cdn_url).to eq(discord_cdn_url)
      end
    end

    context "when tag has valid Discord CDN URL cached" do
      before do
        valid_url = "https://cdn.discordapp.com/attachments/123/456/image.png"
        tag.update!(discord_cdn_url: valid_url)

        # Stub the expiration check to return false
        allow_any_instance_of(Tag).to receive(:discord_url_expired?).and_return(false)
      end

      it "does not update the cached URL" do
        original_url = tag.discord_cdn_url

        described_class.perform_now(tag.id, discord_cdn_url)

        tag.reload
        expect(tag.discord_cdn_url).to eq(original_url)
      end
    end

    context "when tag is not found" do
      it "logs an error and does not raise" do
        expect(Rails.logger).to receive(:error).with(/Tag .+ not found/)

        expect {
          described_class.perform_now("non-existent-id", discord_cdn_url)
        }.not_to raise_error
      end
    end

    context "when update fails" do
      before do
        allow_any_instance_of(Tag).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
        allow(Rails.logger).to receive(:error)
      end

      it "logs an error and raises" do
        expect {
          described_class.perform_now(tag.id, discord_cdn_url)
        }.to raise_error(ActiveRecord::RecordInvalid)

        expect(Rails.logger).to have_received(:error).with(/Failed to cache Discord CDN URL/)
      end
    end
  end
end
