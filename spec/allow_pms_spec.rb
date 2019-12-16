require "rails_helper"

describe TopicCreator do
  fab!(:user0)      { Fabricate(:user, trust_level: TrustLevel[0]) }
  fab!(:user2)      { Fabricate(:user, trust_level: TrustLevel[2]) }
  fab!(:admin)     { Fabricate(:admin) }
  fab!(:moderator)     { Fabricate(:moderator) }

  let(:pm_valid_attrs_to_admin)  { { raw: 'this is a new post', title: 'this is a new title', archetype: Archetype.private_message, target_usernames: admin.username } }
  let(:pm_valid_attrs)  { { raw: 'this is a new post', title: 'this is a new title', archetype: Archetype.private_message, target_usernames: moderator.username } }

  context 'personal message' do
    it "should be possible for a trusted user to send private message" do
      SiteSetting.min_trust_to_send_messages = TrustLevel[2]
      SiteSetting.enable_personal_messages = true
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
        TopicCreator.create(user0, Guardian.new(user0), pm_valid_attrs)
      end.to raise_error(ActiveRecord::Rollback)
    end
  end
end
