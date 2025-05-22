# frozen_string_literal: true

class Eula < ApplicationRecord
  validates :organization_id, presence: true
  validates :status, presence: true

  enum :status, %i[disabled enabled]

  belongs_to :organization

  has_one_attached :file

  after_update :apply_eula_status_to_users, if: :saved_change_to_status?

  private

  def apply_eula_status_to_users
    # rubocop:disable Rails/SkipsModelValidations
    organization.users.update_all(
      eula_enabled: enabled?,
      updated_at: Time.current,
      eula_accepted: false,
      eula_accepted_at: nil
    )
    # rubocop:enable Rails/SkipsModelValidations
  end
end
