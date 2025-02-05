# frozen_string_literal: true

class BvaIntakeReadyForReviewTab < QueueTab
  validate :assignee_is_organization

  attr_accessor :show_reader_link_column, :allow_bulk_assign

  def label
    COPY::ORGANIZATIONAL_QUEUE_PAGE_READY_FOR_REVIEW_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.BVA_READY_FOR_REVIEW_TASKS_TAB_NAME
  end

  def description
    format(COPY::ORGANIZATIONAL_QUEUE_PAGE_BVA_READY_FOR_REVIEW_TASKS_DESCRIPTION, assignee.name)
  end

  def tasks
    Task.includes(*task_includes).visible_in_queue_table_view.where(assigned_to: assignee).active
  end

  def column_names
    BvaIntake::COLUMN_NAMES
  end
end
