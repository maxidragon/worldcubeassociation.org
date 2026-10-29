# frozen_string_literal: true

class RolesMetadataDelegateRegions < ApplicationRecord
  enum :status, {
    senior_delegate: "senior_delegate",
    regional_delegate: "regional_delegate",
    delegate: "delegate",
    junior_delegate: "junior_delegate",
    trainee_delegate: "trainee_delegate",
  }

  STAFF_STATUSES = statuses.values_at(:senior_delegate, :regional_delegate, :delegate, :junior_delegate).freeze

  has_one :user_role, as: :metadata
  has_one :group, through: :user_role
  has_one :user, through: :user_role
  has_one :delegate_region, through: :group, source: :metadata, source_type: "GroupsMetadataDelegateRegions"

  scope :staff, -> { where(status: STAFF_STATUSES) }

  # Past roles count too, so a region that once had Delegates is not announced as new.
  def first_junior_delegate_in_region?
    junior_delegate? && RolesMetadataDelegateRegions.staff
                                                    .joins(:user_role)
                                                    .where(user_roles: { group_id: user_role.group_id })
                                                    .where.not(user_roles: { user_id: user_role.user_id })
                                                    .none?
  end
end
