# frozen_string_literal: true

class Idt::Api::V2::AppealsController < Idt::Api::V1::BaseController
  protect_from_forgery with: :exception
  before_action :verify_access

  def details
    case_search = request.headers["HTTP_CASE_SEARCH"]

    result = if docket_number?(case_search)
               CaseSearchResultsForDocketNumber.new(
                 docket_number: case_search, user: current_user
               ).call
             else
               CaseSearchResultsForVeteranFileNumber.new(
                 file_number_or_ssn: case_search, user: current_user
               ).call
             end

    render_search_results_as_json(result)
  end

  def reader_appeal
    MetricsService.record("VACOLS: Get appeal information for #{appeal_id}",
                          name: "Reader::AppealController.show") do
      render json: {
        appeal: json_appeal(appeal)
      }
    end
  end

  def appeal_documents
    AppealView.find_or_create_by(appeal: appeal, user: current_user).update!(last_viewed_at: Time.zone.now)
    MetricsService.record "Get appeal #{appeal_id} document data" do
      render json: {
        appealDocuments: documents,
        annotations: annotations,
        manifestVbmsFetchedAt: manifest_vbms_fetched_at,
        manifestVvaFetchedAt: manifest_vva_fetched_at
      }
    end
  end

  def appeals_single_document
    if params[:download]
      document = Document.find(document_id)
      document_disposition = "attachment; filename='#{current_document[0]['type']}-#{document_id}.pdf'"
      send_file(
        document.serve,
        type: "application/pdf",
        disposition: document_disposition
      )
    else
      render json: current_document
    end
  end

  private

  # :reek:DuplicateMethodCall { allow_calls: ['result.extra'] }
  # :reek:FeatureEnvy
  def render_search_results_as_json(result)
    if result.success?
      render json: result.extra[:search_results]
    else
      render json: result.to_h, status: result.extra[:status]
    end
  end

  # :reek:FeatureEnvy
  def json_appeal(appeal)
    if appeal.is_a?(Appeal)
      WorkQueue::AppealSerializer.new(appeal, params: { user: current_user })
    elsif appeal.is_a?(LegacyAppeal)
      WorkQueue::LegacyAppealSerializer.new(appeal)
    end
  end

  def docket_number?(search)
    !search.nil? && search.match?(/\d{6}-{1}\d+$/)
  end

  def appeal
    @appeal ||= Appeal.find_appeal_by_uuid_or_find_or_create_legacy_appeal_by_vacols_id(appeal_id)
  end
  helper_method :appeal

  def appeal_id
    params[:appeal_id]
  end

  def document_id
    params[:document_id]
  end

  def annotations
    Annotation.where(document_id: document_ids).map(&:to_hash)
  end

  def document_ids
    @document_ids ||= appeal.document_fetcher.find_or_create_documents!.pluck(:id)
  end

  def current_document
    documents.select { |doc| doc["id"] == document_id.to_i }
  end

  delegate :manifest_vbms_fetched_at, :manifest_vva_fetched_at, to: :appeal

  def documents
    # Create a hash mapping each document_id that has been read to true
    read_documents_hash = current_user.document_views.where(document_id: document_ids)
      .each_with_object({}) do |document_view, object|
      object[document_view.document_id] = true
    end

    tags_by_doc_id = load_tags_by_doc_id

    @documents = appeal.document_fetcher.find_or_create_documents!.map do |document|
      document.to_hash.tap do |object|
        object[:opened_by_current_user] = read_documents_hash[document.id] || false
        object[:tags] = tags_by_doc_id[document.id].to_a
      end
    end
  end

  def load_tags_by_doc_id
    tags_by_doc_id = Hash[document_ids.map { |key, _| [key, Set[]] }]
    Tag.includes(:documents_tags).where(documents_tags: { document_id: document_ids }).each do |tag|
      # tag.documents_tags returns extraneous documents outside document_ids, so
      # only capture tags associated with docs associated with document_ids
      (tag.documents_tags.pluck(:document_id) & document_ids).each do |doc_id|
        tags_by_doc_id[doc_id].add(tag)
      end
    end
    tags_by_doc_id
  end
end
