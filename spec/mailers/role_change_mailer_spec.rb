# frozen_string_literal: true

require "rails_helper"

RSpec.describe RoleChangeMailer do
  describe 'notify_role_start for delegate probation' do
    let(:user_who_made_the_change) { create(:user) }
    let(:senior_delegate) { create(:senior_delegate_role) }
    let(:delegate) { create(:delegate_role, group: senior_delegate.group) }
    let(:role) { create(:probation_role, user: delegate.user) }
    let(:mail) { described_class.notify_role_start(role, user_who_made_the_change) }

    it 'renders the headers' do
      expect(mail.to).to match_array [user_who_made_the_change.email, GroupsMetadataBoard.email, senior_delegate.user.email, UserGroup.teams_committees_group_wrt.metadata.email, UserGroup.teams_committees_group_wic.email,
                                      UserGroup.teams_committees_group_weat.email].flatten
      expect(mail.reply_to).to contain_exactly(user_who_made_the_change.email)
      expect(mail.subject).to eq "New role added for #{role.user.name} in Delegate Probation"
    end

    it 'renders the body' do
      expect(CGI.unescapeHTML(mail.body.encoded)).to match role.user.name
      expect(CGI.unescapeHTML(mail.body.encoded)).to match user_who_made_the_change.name
    end
  end

  describe 'notify_role_start where senior_delegate and user_who_made_the_change are same' do
    let(:senior_delegate) { create(:senior_delegate_role) }
    let(:delegate) { create(:delegate_role, group: senior_delegate.group) }
    let(:role) { create(:probation_role, user: delegate.user) }
    let(:mail) { described_class.notify_role_start(role, senior_delegate.user) }

    it 'renders the headers' do
      expect(mail.to).to contain_exactly(GroupsMetadataBoard.email, senior_delegate.user.email, UserGroup.teams_committees_group_wrt.metadata.email, UserGroup.teams_committees_group_wic.metadata.email,
                                         UserGroup.teams_committees_group_weat.metadata.email)
      expect(mail.reply_to).to contain_exactly(senior_delegate.user.email)
      expect(mail.subject).to eq "New role added for #{role.user.name} in Delegate Probation"
    end

    it 'renders the body' do
      expect(CGI.unescapeHTML(mail.body.encoded)).to match role.user.name
      expect(CGI.unescapeHTML(mail.body.encoded)).to match senior_delegate.user.name
    end
  end

  describe 'notify_role_change for delegate probation' do
    let(:user_who_made_the_change) { create(:user) }
    let(:senior_delegate) { create(:senior_delegate_role) }
    let(:delegate) { create(:delegate_role, group: senior_delegate.group) }
    let(:role) { create(:probation_role, user: delegate.user) }
    let(:mail) { described_class.notify_role_change(role, user_who_made_the_change, [UserRole::UserRoleChange.new(changed_parameter: 'End Date', previous_value: 'Empty', new_value: '01-01-2024')].to_json) }

    it 'renders the headers' do
      expect(mail.to).to match_array [user_who_made_the_change.email, GroupsMetadataBoard.email, senior_delegate.user.email, UserGroup.teams_committees_group_wrt.metadata.email, UserGroup.teams_committees_group_wic.metadata.email,
                                      UserGroup.teams_committees_group_weat.metadata.email].flatten
      expect(mail.reply_to).to contain_exactly(user_who_made_the_change.email)
      expect(mail.subject).to eq "Role changed for #{role.user.name} in Delegate Probation"
    end

    it 'renders the body' do
      expect(CGI.unescapeHTML(mail.body.encoded)).to match role.user.name
      expect(CGI.unescapeHTML(mail.body.encoded)).to match user_who_made_the_change.name
    end
  end

  describe 'notify_role_start for delegate regions' do
    let(:user_who_made_the_change) { create(:user) }
    let(:role) { create(:delegate_role) }
    let(:mail) { described_class.notify_role_start(role, user_who_made_the_change) }

    it 'renders the headers' do
      expect(mail.to).to contain_exactly(
        user_who_made_the_change.email,
        GroupsMetadataBoard.email,
        UserGroup.teams_committees_group_weat.metadata.email,
        UserGroup.teams_committees_group_wic.metadata.email,
        UserGroup.teams_committees_group_wqac.metadata.email,
        UserGroup.teams_committees_group_wrt.metadata.email,
      )
    end
  end

  describe 'notify_role_change for delegate regions' do
    let(:user_who_made_the_change) { create(:user) }
    let(:role) { create(:delegate_role) }
    let(:changes) { [UserRole::UserRoleChange.new(changed_parameter: 'Delegate Region', previous_value: 'Africa', new_value: 'Asia')] }
    let(:mail) { described_class.notify_role_change(role, user_who_made_the_change, changes.to_json) }

    it 'renders the headers' do
      expect(mail.to).to contain_exactly(
        user_who_made_the_change.email,
        GroupsMetadataBoard.email,
        UserGroup.teams_committees_group_weat.metadata.email,
        UserGroup.teams_committees_group_wqac.metadata.email,
        UserGroup.teams_committees_group_wrt.metadata.email,
      )
    end
  end

  describe 'notify_role_end' do
    let(:translator) { create(:regional_delegate_role) }
    let(:user_who_made_the_change) { create(:user, name: 'Sherlock Holmes') }
    let(:mail) { described_class.notify_role_end(translator, user_who_made_the_change) }

    it 'renders the headers' do
      expect(mail.to).to contain_exactly(user_who_made_the_change.email, GroupsMetadataBoard.email, UserGroup.teams_committees_group_weat.metadata.email, UserGroup.teams_committees_group_wfc.metadata.email,
                                         UserGroup.teams_committees_group_wqac.metadata.email, UserGroup.teams_committees_group_wrt.metadata.email)
      expect(mail.reply_to).to contain_exactly(user_who_made_the_change.email)
      expect(mail.subject).to eq "Role removed for #{translator.user.name} in Delegate Regions"
    end

    it 'renders the body' do
      expect(CGI.unescapeHTML(mail.body.encoded)).to match translator.user.name
      expect(CGI.unescapeHTML(mail.body.encoded)).to match user_who_made_the_change.name
    end
  end

  describe 'notify_role_end when the user is still a WCA volunteer' do
    let(:user_who_made_the_change) { create(:user) }
    let(:delegate) { create(:delegate_role, end_date: Date.today) }
    let!(:wrt_role) { create(:wrt_member_role, user: delegate.user) }
    let(:mail) { described_class.notify_role_end(delegate, user_who_made_the_change) }

    it 'notes that they are still a WCA volunteer and lists the remaining roles' do
      body = CGI.unescapeHTML(mail.body.encoded)
      expect(body).to include "#{delegate.user.name} is still a WCA volunteer, so their WCA accounts should stay active"
      expect(body).to include wrt_role.group.name
    end
  end

  describe 'notify_role_end when the user has no other staff roles' do
    let(:user_who_made_the_change) { create(:user) }
    let(:delegate) { create(:delegate_role, end_date: Date.today) }
    let(:mail) do
      create(:translator_role, user: delegate.user)
      described_class.notify_role_end(delegate, user_who_made_the_change)
    end

    it 'does not mention them still being a WCA volunteer' do
      expect(CGI.unescapeHTML(mail.body.encoded)).not_to include 'is still a WCA volunteer'
    end
  end

  describe 'notify_role_start for the first Junior Delegate in a region' do
    let(:user_who_made_the_change) { create(:user) }
    let(:role) { create(:junior_delegate_role) }
    let(:mail) { described_class.notify_role_start(role, user_who_made_the_change) }

    it 'mentions that they are the first Junior Delegate in the region' do
      expect(CGI.unescapeHTML(mail.body.encoded)).to include "#{role.user.name} is the first Junior Delegate in #{role.group.name}"
    end

    it 'does not mention it when someone else already was a Delegate in the region' do
      create(:user_role, :delegate_regions, :delegate_regions_delegate, :inactive, group: role.group)

      expect(CGI.unescapeHTML(mail.body.encoded)).not_to include 'is the first Junior Delegate'
    end

    it 'ignores trainee delegates in the region' do
      create(:trainee_delegate_role, group: role.group)

      expect(CGI.unescapeHTML(mail.body.encoded)).to include "#{role.user.name} is the first Junior Delegate in #{role.group.name}"
    end
  end

  describe 'notify_role_change for the first Junior Delegate in a region' do
    let(:user_who_made_the_change) { create(:user) }
    let(:role) { create(:junior_delegate_role) }
    let(:mail) { described_class.notify_role_change(role, user_who_made_the_change, changes.to_json) }

    context 'when a trainee is promoted' do
      let(:changes) { [UserRole::UserRoleChange.new(changed_parameter: 'Status', previous_value: 'Trainee Delegate', new_value: 'Junior Delegate')] }

      it 'mentions that they are the first Junior Delegate in the region' do
        expect(CGI.unescapeHTML(mail.body.encoded)).to include "#{role.user.name} is the first Junior Delegate in #{role.group.name}"
      end
    end

    context 'when only the location changes' do
      let(:changes) { [UserRole::UserRoleChange.new(changed_parameter: 'Location', previous_value: 'Harare', new_value: 'Bulawayo')] }

      it 'does not mention it' do
        expect(CGI.unescapeHTML(mail.body.encoded)).not_to include 'is the first Junior Delegate'
      end
    end
  end
end
