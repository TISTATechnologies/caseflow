# frozen_string_literal: true

class HearingsSchemas
  class << self
    def update
      ControllerSchema.json do |s|
        s.nested :hearing,
                 optional: false,
                 nullable: false,
                 doc: "Hearing attributes to update",
                 &update_ama_hearing_schema
        s.nested :advance_on_docket_motion,
                 optional: true,
                 nullable: false,
                 doc: "AOD associated with the case",
                 &advance_on_docket_motion
      end
    end

    private

    def common_hearing_fields(s)
      s.string :representative_name,
               optional: true,
               nullable: true,
               doc: "The name of the veteran's POA"
      s.string :witness,
               optional: true,
               nullable: true,
               doc: "The name of the witness of the hearing"
      s.string :military_service,
               optional: true,
               nullable: true,
               doc: "Notes regarding military service"
      s.string :summary,
               optional: true,
               nullable: true,
               doc: "Summary of hearing"
      s.string :notes,
               optional: true,
               nullable: true,
               doc: "Notes about hearing"
      s.string :disposition,
               optional: true,
               nullable: false,
               doc: "Disposition of hearing"
      s.integer :hold_open,
                optional: true,
                nullable: false,
                doc: "Number of days to hold case open for"
      s.bool :transcript_requested,
             optional: true,
             nullable: true,
             doc: "Whether or not a transcript was requested"
      s.bool :prepped,
             optional: true,
             nullable: true,
             doc: "Whether or not the case has been prepped by the judge"
      s.string :scheduled_time_string,
               optional: true,
               nullable: false,
               doc: "The time the hearing was scheduled"
      s.integer :judge_id,
                optional: true,
                nullable: true,
                doc: "The judge associated with the hearing"
      s.string :room,
               optional: true,
               nullable: true,
               doc: "The room the hearing will take place in"
    end

    def update_ama_hearing_schema
      proc do |s|
        common_hearing_fields(s)

        s.date :transcript_sent_date,
               optional: true,
               nullable: false,
               doc: "The date the transcription was sent"
        s.bool :evidence_window_waived,
               optional: true,
               nullable: true,
               doc: "Whether or not the evidence submission window was waived for the hearing"
        s.nested :hearing_location_attributes,
                 optional: true,
                 nullable: true,
                 doc: "The hearing location of the hearing",
                 &hearing_location
        s.nested :virtual_hearing_attributes,
                 optional: true,
                 nullable: true,
                 doc: "Associated data for a virtual hearing",
                 &virtual_hearing
      end
    end

    def hearing_location
      proc do |s|
        s.string :city,
                 optional: true,
                 nullable: true,
                 doc: "The city of the hearing location"
        s.string :state,
                 optional: true,
                 nullable: true,
                 doc: "The state of the hearing location"
        s.string :address,
                 optional: true,
                 nullable: true,
                 doc: "The state of the hearing location"
        s.string :facility_id,
                 optional: true,
                 nullable: false,
                 doc: "The facility ID of the hearing location (defined externally by VA.gov)"
        s.string :facility_type,
                 optional: true,
                 nullable: true,
                 doc: "The facility type of the hearing location"
        s.string :classification,
                 optional: true,
                 nullable: true,
                 doc: "The classification of the facility"
        s.string :name,
                 optional: true,
                 nullable: false,
                 doc: "The name of the facility"
        s.float :distance,
                optional: true,
                nullable: false,
                doc: "The distance of the hearing location from the veteran"
        s.string :zip_code,
                 optional: true,
                 nullable: true,
                 doc: "The zip code of the hearing location"
      end
    end

    def virtual_hearing
      proc do |s|
        s.string :appellant_email,
                 optional: false,
                 nullable: false,
                 doc: "The email address of the appellant/veteran"
        s.string :judge_email,
                 optional: true,
                 nullable: false,
                 doc: "The email address of the judge"
        s.string :representative_email,
                 optional: true,
                 nullable: false,
                 doc: "The email address of the representative"
        s.bool :request_cancelled,
               optional: true,
               nullable: false,
               doc: "If the request for a virtual hearing was cancelled"
        s.string :appellant_tz,
                 optional: true,
                 nullable: false,
                 doc: "The timezone of the appellant/veteran"
        s.string :representative_tz,
                 optional: true,
                 nullable: true,
                 doc: "The timezone of the representative"
      end
    end

    def advance_on_docket_motion
      proc do |s|
        s.integer :person_id,
                  optional: false,
                  nullable: false,
                  doc: "The person the AOD is being granted for"
        s.string :reason,
                 optional: false,
                 nullable: false,
                 doc: "The reason the AOD is being granted"
        s.bool :granted,
               optional: false,
               nullable: true,
               doc: "Whether or not the AOD was granted"
      end
    end
  end
end