# frozen_string_literal: true

class VirtualHearings::ConferenceJob < ApplicationJob
  include VirtualHearings::PexipClient

  private

  def datadog_metric_info
    {
      app_name: Constants.DATADOG_METRICS.HEARINGS.APP_NAME,
      metric_group: Constants.DATADOG_METRICS.HEARINGS.VIRTUAL_HEARINGS_GROUP_NAME
    }
  end

  def log_virtual_hearing_state(virtual_hearing)
    Rails.logger.info(
      "Virtual Hearing for hearing (#{virtual_hearing.hearing_type} [#{virtual_hearing.hearing_id}])"
    )
    Rails.logger.info(
      "Emails Sent: (" \
      "veteran: [#{virtual_hearing.veteran_email_sent} | null?: #{virtual_hearing.veteran_email.nil?}], " \
      "rep: [#{virtual_hearing.representative_email_sent} | null?: #{virtual_hearing.representative_email.nil?}], " \
      "judge: [#{virtual_hearing.judge_email_sent} | null?: #{virtual_hearing.judge_email.nil?}])"
    )
  end
end
