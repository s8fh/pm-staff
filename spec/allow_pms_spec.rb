# frozen_string_literal: true

require "rails_helper"

describe TopicCreator do
  fab!(:user0) { Fabricate(:user, trust_level: TrustLevel[0]) }
  fab!(:normal_user) do
    Fabricate(:user, trust_level: TrustLevel[1], admin: false, moderator: false)
  end
  fab!(:user2) { Fabricate(:user, trust_level: TrustLevel[2]) }
  fab!(:admin) { Fabricate(:admin) }
  fab!(:moderator) { Fabricate(:moderator) }

  let(:pm_valid_attrs_to_admin) do
    {
      raw: "this is a new post",
      title: "this is a new title",
      archetype: Archetype.private_message,
      target_usernames: admin.username,
    }
  end
  let(:pm_valid_attrs) do
    {
      raw: "this is a new post",
      title: "this is a new title",
      archetype: Archetype.private_message,
      target_usernames: moderator.username,
    }
  end
  let(:pm_to_normal_user) do
    {
      raw: "this is another new post",
      title: "this is still a new title",
      archetype: Archetype.private_message,
      target_usernames: user2.username,
    }
  end

  context "when sending a personal message" do
    it "should be possible for a trusted user to send private message" do
      puts "setting the settings"
      SiteSetting.min_trust_to_send_messages = TrustLevel[2]
      SiteSetting.enable_personal_messages = true
      SiteSetting.allow_pm_allowed_pm_groups = "staff"
      expect(TopicCreator.create(user2, Guardian.new(user2), pm_valid_attrs)).to be_valid
    end

    it "should be possible for a new user to send private message to admin" do
      SiteSetting.min_trust_to_send_messages = TrustLevel[4]
      SiteSetting.enable_personal_messages = true
      expect(TopicCreator.create(user0, Guardian.new(user0), pm_valid_attrs_to_admin)).to be_valid
    end

    it "should not be possible for a new user to send private message to normal user" do
      SiteSetting.min_trust_to_send_messages = TrustLevel[4]
      SiteSetting.enable_personal_messages = true
      expect do
        TopicCreator.create(user0, Guardian.new(normal_user), pm_to_normal_user)
      end.to raise_error(ActiveRecord::Rollback)
    end

    it "can read a group page" do
      get "/g/admins"
      expect(response.status).to eq(200)
    end
  end
end
