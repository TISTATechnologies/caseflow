# frozen_string_literal: true

class Fakes::PowerOfAttorneyStore < Fakes::PersistentStore
  class << self
    def redis_ns
      "powers_of_attorney_#{Rails.env}"
    end
  end

  def all_participant_ids
    prefix = "#{self.class.redis_ns}:"
    all_keys.map { |key| key.sub(/^#{prefix}/, "") }
  end

  def get_power_of_attorney_record_by_file_number(file_number)
  end

  def store_power_of_attorney_record(representative_participant_id, record)
    deflate_and_store(representative_participant_id, record)
  end

  def store_representative_record(representative_participant_id, record)
    deflate_and_store(representative_participant_id, record)
  end

  def poas_list
  end
end
