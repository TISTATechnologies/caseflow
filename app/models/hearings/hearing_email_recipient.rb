# frozen_string_literal: true

class HearingEmailRecipient < CaseflowRecord
  RECIPIENT_ROLES = {
    appellant: "appellant",
    representative: "representative",
    judge: "judge"
  }.freeze

  RECIPIENT_TITLES = {
    judge: "Judge",
    appellant: "Appellant",
    representative: "Representative"
  }.freeze

  belongs_to :hearing, polymorphic: true
  has_many :email_events, class_name: "SentHearingEmailEvent", foreign_key: :email_recipient_id

  def reminder_sent_at
    email_events
      .where(email_type: "reminder", recipient_role: role)
      &.order(:sent_at)
      &.last
      &.sent_at
  end
end