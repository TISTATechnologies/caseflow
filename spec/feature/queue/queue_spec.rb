require "rails_helper"
# rubocop:disable Style/FormatString

def click_dropdown(opt_idx, container = page)
  dropdown = container.find(".Select-control")
  dropdown.click
  yield if block_given?
  dropdown.sibling(".Select-menu-outer").find("div[id$='--option-#{opt_idx}']").click
end

RSpec.feature "Queue" do
  before do
    Fakes::Initializer.load!
    FeatureToggle.enable!(:queue_phase_two)
  end

  after do
    FeatureToggle.disable!(:queue_phase_two)
  end

  let(:documents) do
    [
      Generators::Document.create(
        filename: "My BVA Decision",
        type: "BVA Decision",
        received_at: 7.days.ago,
        vbms_document_id: 6,
        category_procedural: true,
        tags: [
          Generators::Tag.create(text: "New Tag1"),
          Generators::Tag.create(text: "New Tag2")
        ],
        description: Generators::Random.word_characters(50)
      ),
      Generators::Document.create(
        filename: "My Form 9",
        type: "Form 9",
        received_at: 5.days.ago,
        vbms_document_id: 4,
        category_medical: true,
        category_other: true
      ),
      Generators::Document.create(
        filename: "My NOD",
        type: "NOD",
        received_at: 1.day.ago,
        vbms_document_id: 3
      )
    ]
  end
  let(:vacols_record) { :remand_decided }
  let(:appeals) do
    [
      Generators::LegacyAppeal.build(
        vbms_id: "123456789S",
        vacols_record: vacols_record,
        documents: documents
      ),
      Generators::LegacyAppeal.build(
        vbms_id: "115555555S",
        vacols_record: vacols_record,
        documents: documents,
        issues: []
      )
    ]
  end
  let!(:issues) { [Generators::Issue.build] }
  let! :attorney_user do
    User.authenticate!(roles: ["System Admin"])
  end

  let!(:vacols_tasks) { Fakes::QueueRepository.tasks_for_user(attorney_user.css_id) }
  let!(:vacols_appeals) { Fakes::QueueRepository.appeals_from_tasks(vacols_tasks) }

  context "queue case search for appeals using veteran id" do
    let(:appeal) { appeals.first }
    let!(:veteran_id_with_no_appeals) { Generators::Random.unique_ssn }
    let(:invalid_veteran_id) { "obviouslyinvalidveteranid" }

    context "when invalid Veteran ID input" do
      before do
        visit "/queue"
        fill_in "searchBar", with: invalid_veteran_id
        click_on "Search"
      end

      it "page displays invalid Veteran ID message" do
        expect(page).to have_content(sprintf(COPY::CASE_SEARCH_ERROR_INVALID_ID_HEADING, invalid_veteran_id))
      end

      it "searching in search bar works" do
        fill_in "searchBar", with: appeal.sanitized_vbms_id
        click_on "Search"

        expect(page).to have_content("1 case found for")
        expect(page).to have_content(COPY::CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE)
      end

      it "clicking on the x in the search bar returns browser to queue list page" do
        click_on "button-clear-search"
        expect(page).to have_content(COPY::ATTORNEY_QUEUE_TABLE_TITLE)
      end
    end

    context "when no appeals found" do
      before do
        visit "/queue"
        fill_in "searchBar", with: veteran_id_with_no_appeals
        click_on "Search"
      end

      it "page displays no cases found message" do
        expect(page).to have_content(
          sprintf(COPY::CASE_SEARCH_ERROR_NO_CASES_FOUND_HEADING, veteran_id_with_no_appeals)
        )
      end

      it "searching in search bar works" do
        fill_in "searchBar", with: appeal.sanitized_vbms_id
        click_on "Search"

        expect(page).to have_content("1 case found for")
        expect(page).to have_content(COPY::CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE)
      end

      it "clicking on the x in the search bar returns browser to queue list page" do
        click_on "button-clear-search"
        expect(page).to have_content(COPY::ATTORNEY_QUEUE_TABLE_TITLE)
      end
    end

    context "when backend encounters an error" do
      before do
        allow(LegacyAppeal).to receive(:fetch_appeals_by_file_number).and_raise(StandardError)
        visit "/queue"
        fill_in "searchBar", with: appeal.sanitized_vbms_id
        click_on "Search"
      end

      it "displays error message on same page" do
        expect(page).to have_content(sprintf(COPY::CASE_SEARCH_ERROR_UNKNOWN_ERROR_HEADING, appeal.sanitized_vbms_id))
      end

      it "searching in search bar produces another error" do
        fill_in "searchBar", with: veteran_id_with_no_appeals
        click_on "Search"

        expect(page).to have_content(sprintf(COPY::CASE_SEARCH_ERROR_UNKNOWN_ERROR_HEADING, veteran_id_with_no_appeals))
      end
    end

    context "when one appeal found" do
      before do
        visit "/queue"
        fill_in "searchBar", with: appeal.sanitized_vbms_id
        click_on "Search"
      end

      it "page displays table of results" do
        expect(page).to have_content("1 case found for")
        expect(page).to have_content(COPY::CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE)
      end

      it "search bar stays in top right" do
        expect(page).to have_selector("#searchBar")
      end

      it "clicking on the x in the search bar clears the search bar" do
        click_on "button-clear-search"
        expect(find("#searchBar")).to have_content("")
      end

      it "clicking on docket number sends us to the case details page" do
        click_on appeal.docket_number
        expect(page.current_path).to eq("/queue/appeals/#{appeal.vacols_id}")

        expect(page).not_to have_content "Select an action"
      end

      scenario "found appeal is paper case" do
        visit "/queue"
        fill_in "searchBar", with: "384920173S"
        click_on "Search"

        expect(page).to have_content("1 case found for “Polly A Carter (384920173)”")
        expect(page).to have_content(COPY::IS_PAPER_CASE)
      end
    end
  end

  context "case search from home page" do
    let(:appeal) { appeals.first }
    let!(:veteran_id_with_no_appeals) { Generators::Random.unique_ssn }
    let(:invalid_veteran_id) { "obviouslyinvalidveteranid" }
    let(:search_homepage_title) { COPY::CASE_SEARCH_HOME_PAGE_HEADING }
    let(:search_homepage_subtitle) { COPY::CASE_SEARCH_INPUT_INSTRUCTION }

    before do
      User.unauthenticate!
      User.authenticate!(css_id: "BVAAABSHIRE")
      FeatureToggle.enable!(:case_search_home_page)
    end
    after do
      FeatureToggle.disable!(:case_search_home_page)
    end

    scenario "logo links to / instead of /queue" do
      visit "/"
      have_link("Caseflow", href: "/")
    end

    context "when invalid Veteran ID input" do
      before do
        visit "/"
        fill_in "searchBarEmptyList", with: invalid_veteran_id
        click_on "Search"
      end

      it "page displays invalid Veteran ID message" do
        expect(page).to have_content(sprintf(COPY::CASE_SEARCH_ERROR_INVALID_ID_HEADING, invalid_veteran_id))
      end

      it "search bar does not appear in top right of page" do
        expect(page).to_not have_selector("#searchBar")
        expect(page).to have_selector("#searchBarEmptyList")
      end

      it "searching in search bar works" do
        fill_in "searchBarEmptyList", with: appeal.sanitized_vbms_id
        click_on "Search"

        expect(page).to have_content("1 case found for")
        expect(page).to have_content(COPY::CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE)
      end

      it "clicking on the x in the search bar returns browser to queue list page" do
        click_on "button-clear-search"
        expect(page).to have_content(search_homepage_title)
        expect(page).to have_content(search_homepage_subtitle)
      end
    end

    context "when no appeals found" do
      before do
        visit "/"
        fill_in "searchBarEmptyList", with: veteran_id_with_no_appeals
        click_on "Search"
      end

      it "page displays no cases found message" do
        expect(page).to have_content(
          sprintf(COPY::CASE_SEARCH_ERROR_NO_CASES_FOUND_HEADING, veteran_id_with_no_appeals)
        )
      end

      it "search bar does not appear in top right of page" do
        expect(page).to_not have_selector("#searchBar")
        expect(page).to have_selector("#searchBarEmptyList")
      end

      it "searching in search bar works" do
        fill_in "searchBarEmptyList", with: appeal.sanitized_vbms_id
        click_on "Search"

        expect(page).to have_content("1 case found for")
        expect(page).to have_content(COPY::CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE)
      end

      it "clicking on the x in the search bar returns browser to queue list page" do
        click_on "button-clear-search"
        expect(page).to have_content(search_homepage_title)
        expect(page).to have_content(search_homepage_subtitle)
      end
    end

    context "when backend encounters an error" do
      before do
        allow(LegacyAppeal).to receive(:fetch_appeals_by_file_number).and_raise(StandardError)
        visit "/"
        fill_in "searchBarEmptyList", with: appeal.sanitized_vbms_id
        click_on "Search"
      end

      it "displays error message" do
        expect(page).to have_content(sprintf(COPY::CASE_SEARCH_ERROR_UNKNOWN_ERROR_HEADING, appeal.sanitized_vbms_id))
      end

      it "search bar does not appear in top right of page" do
        expect(page).to_not have_selector("#searchBar")
        expect(page).to have_selector("#searchBarEmptyList")
      end

      it "searching in search bar works" do
        fill_in "searchBarEmptyList", with: veteran_id_with_no_appeals
        click_on "Search"
        expect(page).to have_content(sprintf(COPY::CASE_SEARCH_ERROR_UNKNOWN_ERROR_HEADING, veteran_id_with_no_appeals))
      end

      it "clicking on the x in the search bar returns browser to queue list page" do
        click_on "button-clear-search"
        expect(page).to have_content(search_homepage_title)
        expect(page).to have_content(search_homepage_subtitle)
      end
    end

    context "when one appeal found" do
      before do
        visit "/"
        fill_in "searchBarEmptyList", with: appeal.sanitized_vbms_id
        click_on "Search"
      end

      it "page displays table of results" do
        expect(page).to have_content("1 case found for")
        expect(page).to have_content(COPY::CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE)
      end

      it "search bar displayed in top right of page" do
        expect(page).to have_selector("#searchBar")
        expect(page).to_not have_selector("#searchBarEmptyList")
      end

      it "clicking on docket number sends us to the case details page" do
        click_on appeal.docket_number
        expect(page.current_path).to eq("/queue/appeals/#{appeal.vacols_id}")
      end

      it "clicking on back breadcrumb from detail view sends us to search results page" do
        click_on appeal.docket_number
        expect(page.current_path).to eq("/queue/appeals/#{appeal.vacols_id}")

        click_on sprintf(COPY::BACK_TO_SEARCH_RESULTS_LINK_LABEL, appeal.veteran_full_name)
        expect(page).to have_content("1 case found for")
        expect(page).to have_content(COPY::CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE)
        expect(page.current_path).to match(/^\/cases\/\d+$/)
      end

      it "clicking on back breadcrumb sends us to empty search home page", skip: "the test is non-deterministic" do
        page.find("h1").find("a").click
        expect(page).to have_content(search_homepage_title)
        expect(page).to have_content(search_homepage_subtitle)
        expect(page.current_path).to eq("/")
      end
    end
  end

  context "loads queue table view" do
    scenario "table renders row per task" do
      visit "/queue"

      expect(page).to have_content(COPY::ATTORNEY_QUEUE_TABLE_TITLE)
      expect(find("tbody").find_all("tr").length).to eq(vacols_tasks.length)

      vet_not_appellant = vacols_appeals.reject { |a| a.appellant_first_name.nil? }.first
      vna_appeal_row = find("tbody").find("#table-row-#{vet_not_appellant.vacols_id}")
      first_cell = vna_appeal_row.find_all("td").first

      expect(first_cell).to have_content("#{vet_not_appellant.veteran_full_name} (#{vet_not_appellant.vbms_id})")
      expect(first_cell).to have_content(COPY::CASE_DIFF_VETERAN_AND_APPELLANT)

      paper_case = vacols_appeals.select { |a| a.file_type.eql? "Paper" }.first
      pc_appeal_row = find("tbody").find("#table-row-#{paper_case.vacols_id}")
      first_cell = pc_appeal_row.find_all("td").first

      expect(first_cell).to have_content("#{paper_case.veteran_full_name} (#{paper_case.vbms_id.delete('S')})")
      expect(first_cell).to have_content(COPY::IS_PAPER_CASE)
    end
  end

  context "loads attorney task detail views" do
    before do
      User.unauthenticate!
      User.authenticate!(roles: ["System Admin"])
    end

    context "loads appeal summary view" do
      scenario "appeal has hearing" do
        appeal = vacols_appeals.reject { |a| a.hearings.empty? }.first
        hearing = appeal.hearings.first

        visit "/queue"

        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"

        expect(page).to have_content("Select an action")

        hearing_preference = hearing.type.to_s.split("_").map(&:capitalize).join(" ")
        expect(page).to have_content("Type: #{hearing_preference}")

        if hearing.disposition.eql? :cancelled
          expect(page).to have_content("Disposition: Cancelled")
        else
          expect(page).to have_content("Date: #{hearing.date.strftime('%-m/%-e/%y')}")
          expect(page).to have_content("Judge: #{hearing.user.full_name}")

          unless hearing.hearing_views.empty?
            worksheet_link = page.find("a[href='/hearings/#{hearing.id}/worksheet/print']")
            expect(worksheet_link.text).to eq("View Hearing Worksheet")
          end
        end
      end

      scenario "appeal has no hearing" do
        task = vacols_tasks.select { |t| t.hearings.empty? }.first
        appeal = vacols_appeals.select { |a| a.vacols_id.eql? task.vacols_id }.first
        appeal_ro = appeal.regional_office

        visit "/queue"

        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"

        expect(page).not_to have_content("Hearing preference")

        expect(page.document.text).to match(/#{COPY::CASE_SNAPSHOT_ABOUT_BOX_TYPE_LABEL} CAVC/i)
        expect(page).to have_content("Power of Attorney")
        expect(page).to have_content(appeal.representative)
        expect(page).to have_content("Regional Office: #{appeal_ro.city} (#{appeal_ro.key.sub('RO', '')})")
      end
    end

    context "loads appellant detail view" do
      scenario "veteran is the appellant" do
        appeal = vacols_appeals.first

        visit "/queue"

        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"

        expect(page).to have_content("Veteran Details")
        expect(page).to have_content("The veteran is the appellant.")

        expect(page).to have_content("She/Her")
        # rubocop:disable Style/FormatStringToken
        expect(page).to have_content(appeal.veteran_date_of_birth.strftime("%-m/%e/%Y"))
        # rubocop:enable Style/FormatStringToken
        expect(page).to have_content("The veteran is the appellant.")
      end

      scenario "veteran is not the appellant" do
        appeal = vacols_appeals.reject { |a| a.appellant_name.nil? }.first

        visit "/queue"

        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"

        expect(page).to have_content("Appellant Details")
        expect(page).to have_content("Veteran Details")
        expect(page).to have_content(COPY::CASE_DIFF_VETERAN_AND_APPELLANT)

        expect(page).to have_content(appeal.appellant_name)
        expect(page).to have_content(appeal.appellant_relationship)
        expect(page).to have_content(appeal.appellant_address_line_1)
      end
    end

    context "links to reader" do
      scenario "from appellant details page" do
        appeal = vacols_appeals.first
        visit "/queue"

        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"

        sleep 1
        expect(page).to have_content("Your Queue > #{appeal.veteran_full_name}")

        click_on "View #{appeal.documents.count} documents"

        # ["Caseflow", "> Reader"] are two elements, space handled by margin-left on second
        expect(page).to have_content("Caseflow> Reader")
        expect(page).to have_content("Back to #{appeal.veteran_full_name} (#{appeal.vbms_id})")

        click_on "Caseflow"
        expect(page.current_path).to eq "/queue"
      end
    end

    context "displays issue dispositions" do
      scenario "from appellant details page" do
        appeal = vacols_appeals.first
        visit "/queue"
        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"
        expect(page).to have_content("Disposition: 1 - Allowed")
      end
    end
  end

  context "loads judge task detail views" do
    before do
      FeatureToggle.enable!(:test_facols)
      FeatureToggle.enable!(:judge_queue)
      FeatureToggle.enable!(:judge_assignment)
      User.unauthenticate!
      User.authenticate!(css_id: "BVAAABSHIRE")
      RequestStore[:current_user] = judge
    end

    after do
      FeatureToggle.disable!(:test_facols)
      FeatureToggle.disable!(:judge_queue)
      FeatureToggle.disable!(:judge_assignment)
      User.unauthenticate!
      User.authenticate!
    end

    let!(:attorney) do
      User.create(
        css_id: "BVASCASPER1",
        station_id: User::BOARD_STATION_ID,
        full_name: "Archibald Franzduke"
      )
    end
    let!(:judge) { User.create(css_id: "BVAAABSHIRE", station_id: User::BOARD_STATION_ID) }
    let!(:judge_staff) { create(:staff, :judge_role, slogid: judge.css_id, sdomainid: judge.css_id) }
    let!(:vacols_case) do
      create(
        :case,
        :assigned,
        user: judge,
        assigner: attorney,
        correspondent: create(:correspondent, snamef: "Feffy", snamel: "Smeterino"),
        document_id: "1234567890"
      )
    end

    scenario "displays who prepared task" do
      tasks, appeals = LegacyWorkQueue.tasks_with_appeals(judge, "judge")

      task = tasks.first
      appeal = appeals.first
      visit "/queue"

      click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id.sub('S', '')})"

      preparer_name = "#{task.assigned_by.first_name[0]}. #{task.assigned_by.last_name}"
      expect(page.document.text).to match(/#{COPY::CASE_SNAPSHOT_DECISION_PREPARER_LABEL} #{preparer_name}/i)
      expect(page.document.text).to match(/#{COPY::CASE_SNAPSHOT_DECISION_DOCUMENT_ID_LABEL} #{task.document_id}/i)
    end
  end

  context "loads attorney checkout views" do
    scenario "starts checkout flow from case detail view" do
      appeal = vacols_appeals.first
      visit "/queue"

      click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"

      click_dropdown 0

      expect(page).to have_content "Select Dispositions"

      cancel_button = page.find "#button-cancel-button"
      expect(cancel_button.text).to eql "Cancel"
      cancel_button.click

      cancel_modal = page.find ".cf-modal"
      expect(cancel_modal.matches_css?(".active")).to eq true
      cancel_modal.find(".usa-button-warning").click

      click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"

      click_dropdown 1

      expect(page).to have_content "Submit OMO for Review"

      cancel_button = page.find "#button-cancel-button"
      expect(cancel_button.text).to eql "Cancel"

      back_button = page.find "#button-back-button"
      expect(back_button.text).to eql "Back"
    end

    context "prepares/fails to submit decision" do
      scenario "fails to submit omo decision" do
        appeal = vacols_appeals.first
        visit "/queue"

        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"
        click_dropdown 1

        expect(page).to have_link("Your Queue", href: "/queue")
        expect(page).to have_link(appeal.veteran_full_name, href: "/queue/appeals/#{appeal.vacols_id}")
        expect(page).to have_link("Submit OMO", href: "/queue/appeals/#{appeal.vacols_id}/submit")

        expect(page).to have_content "Back"

        click_on "Continue"

        expect(page).to have_content("This field is required")
        expect(page.find_all(".usa-input-error-message").length).to eq(3)
      end

      scenario "selects issue dispositions" do
        appeal = vacols_appeals.select { |a| a.issues.length > 1 }.first
        visit "/queue"

        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"
        click_dropdown 0

        expect(page).to have_content("Select Dispositions")

        table_rows = page.find_all("tr[id^='table-row-']")
        expect(table_rows.length).to eq(appeal.issues.length)

        # do not select all dispositions
        table_rows[0..0].each { |row| click_dropdown 1, row }

        click_on "Continue"

        table_rows[1..-1].each do |row|
          dropdown_border = row.find(".issue-disposition-dropdown").native.css_value("border-left")
          expect(dropdown_border).to eq("4px solid rgb(205, 32, 38)")
        end

        # select all dispositions
        table_rows.each { |row| click_dropdown 2, row }

        click_on "Continue"

        expect(page.current_path).to eq("/queue/appeals/#{appeal.vacols_id}/submit")
      end

      scenario "edits issue information" do
        appeal = vacols_appeals.select { |a| a.issues.map(&:disposition).uniq.eql? [nil] }.first
        visit "/queue"

        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"
        click_dropdown 0

        expect(page).to have_content("Select Dispositions")

        safe_click("a[href='/queue/appeals/#{appeal.vacols_id}/dispositions/edit/1']")
        expect(page).to have_content("Edit Issue")

        enabled_fields = page.find_all(".Select--single:not(.is-disabled)")

        field_values = enabled_fields.map do |row|
          # changing options at the top of the form affects what options are enabled further down
          next if row.matches_css? ".is-disabled"

          click_dropdown 1, row
          row.find(".Select-value-label").text
        end
        fill_in "Notes:", with: "this is the note"

        click_on "Continue"

        expect(page).to have_content "You updated issue 1."
        expect(page).to have_content "Program: #{field_values.first}"
        expect(page).to have_content "Issue: #{field_values.second}"
        expect(page).to have_content field_values.last # diagnostic code
        expect(page).to have_content "Note: this is the note"
      end

      scenario "shows/hides diagnostic code option" do
        appeal = vacols_appeals.select { |a| a.issues.map(&:disposition).uniq.eql? [nil] }.first
        visit "/queue"

        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"
        click_dropdown 0

        expect(page).to have_content "Select Dispositions"

        diag_code_no_l2 = %w[4 5 0 *]
        no_diag_code_no_l2 = %w[4 5 1]
        diag_code_w_l2 = %w[4 8 0 1 *]
        no_diag_code_w_l2 = %w[4 8 0 2]

        [diag_code_no_l2, no_diag_code_no_l2, diag_code_w_l2, no_diag_code_w_l2].each do |opt_set|
          safe_click "a[href='/queue/appeals/#{appeal.vacols_id}/dispositions/edit/1']"
          expect(page).to have_content "Edit Issue"
          selected_vals = select_issue_level_options(opt_set)
          click_on "Continue"
          selected_vals.each { |v| expect(page).to have_content v }
        end
      end

      def select_issue_level_options(opts)
        Array.new(5).map.with_index do |*, row_idx|
          # Issue level 2 and diagnostic code dropdowns render based on earlier
          # values, so we have to re-get elements per loop. There are at most 5
          # dropdowns rendered: Program, Type, Levels 1, 2, Diagnostic Code
          field_options = page.find_all ".Select--single"
          row = field_options[row_idx]

          next unless row

          row.find(".Select-control").click

          if opts[row_idx].eql? "*"
            # there're about 800 diagnostic code options, but getting the count
            # of '.Select-option's from the DOM takes a while
            row.find("div[id$='--option-#{rand(800)}']").click
          elsif opts[row_idx].is_a? String
            row.find("div[id$='--option-#{opts[row_idx]}']").click
          end
          row.find(".Select-value-label").text
        end
      end

      scenario "adds issue" do
        appeal = vacols_appeals.reject { |a| a.issues.empty? }.first
        visit "/queue"

        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"
        click_dropdown 0

        expect(page).to have_content "Select Dispositions"

        click_on "Add Issue"
        expect(page).to have_content "Add Issue"

        delete_btn = find("button", text: "Delete Issue")
        expect(delete_btn.disabled?).to eq true

        fields = page.find_all ".Select--single"

        field_values = fields.map do |row|
          next if row.matches_css? ".is-disabled"

          click_dropdown 0, row
          row.find(".Select-value-label").text
        end
        fill_in "Notes:", with: "added issue"

        click_on "Continue"

        expect(page).to have_content "You created a new issue."
        expect(page).to have_content "Program: #{field_values.first}"
        expect(page).to have_content "Issue: #{field_values.second}"
        expect(page).to have_content field_values.last
        expect(page).to have_content "Note: added issue"

        click_on "Your Queue"

        issue_count = find(:xpath, "//tbody/tr[@id='table-row-#{appeal.vacols_id}']/td[4]").text
        expect(issue_count).to eq "2"
      end

      scenario "deletes issue" do
        appeal = vacols_appeals.select { |a| a.issues.length > 1 }.first
        old_issues = appeal.issues
        visit "/queue"

        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"
        click_dropdown 0

        expect(page).to have_content("Select Dispositions")

        issue_rows = page.find_all("tr[id^='table-row-']")
        expect(issue_rows.length).to eq(appeal.issues.length)

        safe_click("a[href='/queue/appeals/#{appeal.vacols_id}/dispositions/edit/1']")
        expect(page).to have_content("Edit Issue")

        issue_idx = appeal.issues.index { |i| i.vacols_sequence_id.eql? 1 }

        click_on "Delete Issue"
        expect(page).to have_content "Delete Issue?"
        click_on "Delete issue"

        expect(page).to have_content("You deleted issue #{issue_idx + 1}.")

        issue_rows = page.find_all("tr[id^='table-row-']")
        expect(issue_rows.length).to eq(old_issues.length - 1)

        click_on "Your Queue"

        issue_count = find(:xpath, "//tbody/tr[@id='table-row-#{appeal.vacols_id}']/td[4]").text
        expect(issue_count).to eq "4"
      end
    end

    context "submits decision" do
      scenario "submits omo decision" do
        appeal = vacols_appeals.first
        visit "/queue"

        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"
        click_dropdown 1

        expect(page).to have_content("Submit OMO for Review")

        click_label("omo-type_OMO - VHA")
        click_label("overtime")
        fill_in "document_id", with: "12345"
        fill_in "notes", with: "notes"

        safe_click("#select-judge")
        click_dropdown 1
        expect(page).to have_content("Andrew Mackenzie")

        click_on "Continue"
        sleep 1
        expect(page).to(
          have_content(
            "Thank you for drafting #{appeal.veteran_full_name}'s outside medical
            opinion (OMO) request. It's been sent to Andrew Mackenzie for review."
          )
        )
        expect(page.current_path).to eq("/queue")
      end

      scenario "submits draft decision" do
        appeal = vacols_appeals.select { |a| a.issues.length > 1 }.first
        visit "/queue"

        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"
        click_dropdown 0

        issue_rows = page.find_all("tr[id^='table-row-']")
        expect(issue_rows.length).to eq(appeal.issues.length)

        issue_rows.each do |row|
          row.find(".Select-control").click
          row.find("div[id$='--option-#{issue_rows.index(row) % 7}']").click
        end

        click_on "Continue"
        expect(page).to have_content("Select Remand Reasons")
        expect(page).to have_content(appeal.issues.first.note)

        page.execute_script("return document.querySelectorAll('div[class^=\"checkbox-wrapper-\"]')")
          .sample(4)
          .each(&:click)

        page.find_all("input[type='radio'] + label").to_a.each_with_index do |label, idx|
          label.click unless (idx % 2).eql? 0
        end

        click_on "Continue"
        expect(page).to have_content("Submit Draft Decision for Review")

        fill_in "document_id", with: "12345"
        fill_in "notes", with: "this is a decision note"

        safe_click "#select-judge"
        click_dropdown 1
        expect(page).to have_content("Andrew Mackenzie")

        click_on "Continue"
        sleep 1
        expect(page).to(
          have_content(
            "Thank you for drafting #{appeal.veteran_full_name}'s decision.
            It's been sent to Andrew Mackenzie for review."
          )
        )
        expect(page.current_path).to eq("/queue")
      end
    end
  end

  context "loads judge checkout views" do
    before do
      FeatureToggle.enable!(:test_facols)
      FeatureToggle.enable!(:judge_queue)
      FeatureToggle.enable!(:judge_assignment)
      User.unauthenticate!
      User.authenticate!(css_id: "BVAAABSHIRE")
      RequestStore[:current_user] = judge
    end

    after do
      FeatureToggle.disable!(:test_facols)
      FeatureToggle.disable!(:judge_queue)
      FeatureToggle.disable!(:judge_assignment)
      User.unauthenticate!
      User.authenticate!
    end

    let!(:attorney) do
      User.create(
        css_id: "BVASCASPER1",
        station_id: User::BOARD_STATION_ID,
        full_name: "Bendytoots Cumbersnatch"
      )
    end
    let!(:judge) { User.create(css_id: "BVAAABSHIRE", station_id: User::BOARD_STATION_ID) }
    let!(:judge_staff) { create(:staff, :judge_role, slogid: judge.css_id, sdomainid: judge.css_id) }
    let!(:vacols_cases) do
      [
        create(
          :case,
          :assigned,
          user: judge,
          assigner: attorney,
          case_issues: [create(:case_issue, :disposition_allowed)],
          correspondent: create(:correspondent, snamef: "Jeffy", snamel: "Veterino"),
          work_product: :draft_decision
        ),
        create(
          :case,
          :assigned,
          user: judge,
          assigner: attorney,
          case_issues: [create(:case_issue, :disposition_denied)],
          correspondent: create(:correspondent, snamef: "Armide", snamel: "Forceso"),
          work_product: :omo_request
        )
      ]
    end

    scenario "starts dispatch checkout flow" do
      _, appeals = LegacyWorkQueue.tasks_with_appeals(judge, "judge")

      # get draft decision appeal vacols_id
      vacols_id = VACOLS::Decass.all.find(&:draft_decision?).defolder
      appeal = appeals.find { |a| a.vacols_id.eql?(vacols_id) }

      visit "/queue"

      # TODO: appeal vbms_id ends w/S. better way to strip?
      click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id[0..-2]})"

      click_dropdown 0 do
        visible_options = page.find_all(".Select-option")
        expect(visible_options.length).to eq 1
        expect(visible_options.first.text).to eq COPY::JUDGE_CHECKOUT_DISPATCH_LABEL
      end

      click_on "Continue"
      expect(page).to have_content("Evaluate Decision")

      click_on "Continue"
      expect(page).to have_content("Choose one")
      sleep 2

      radio_group_cls = "cf-form-showhide-radio cf-form-radio usa-input-error"
      case_complexity_opts = page.find_all(:xpath, "//fieldset[@class='#{radio_group_cls}'][1]//label")
      case_quality_opts = page.find_all(:xpath, "//fieldset[@class='#{radio_group_cls}'][2]//label")

      [case_complexity_opts, case_quality_opts].each { |l| l.sample(1).first.click }
      # areas of improvement
      page.find_all(".question-label").sample(2).each(&:double_click)

      fill_in "additional-factors", with: "this is the note"

      click_on "Continue"

      expect(page).to have_content(COPY::JUDGE_CHECKOUT_DISPATCH_SUCCESS_MESSAGE_TITLE % appeal.veteran_full_name)
    end

    scenario "completes assign to omo checkout flow" do
      _, appeals = LegacyWorkQueue.tasks_with_appeals(judge, "judge")

      vacols_id = VACOLS::Decass.all.find(&:omo_request?).defolder
      appeal = appeals.find { |a| a.vacols_id.eql?(vacols_id) }

      visit "/queue"

      click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id[0..-2]})"

      click_dropdown 0 do
        visible_options = page.find_all(".Select-option")
        expect(visible_options.length).to eq 1
        expect(visible_options.first.text).to eq COPY::JUDGE_CHECKOUT_OMO_LABEL
      end

      expect(page).to have_content(COPY::JUDGE_CHECKOUT_OMO_SUCCESS_MESSAGE_TITLE % appeal.veteran_full_name)
    end
  end

  context "pop breadcrumb" do
    scenario "goes back from submit decision view" do
      appeal = vacols_appeals.select { |a| a.issues.map(&:disposition).uniq.eql? [nil] }.first
      visit "/queue"

      click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"
      sleep 1
      click_dropdown 0

      issue_rows = page.find_all("tr[id^='table-row-']")
      expect(issue_rows.length).to eq(appeal.issues.length)

      issue_rows.each { |row| click_dropdown 2, row }

      click_on "Continue"

      expect(page).to have_content("Submit Draft Decision for Review")
      expect(page).to have_content("Your Queue > #{appeal.veteran_full_name} > Select Dispositions > Submit")

      click_on "Back"

      expect(page).to have_content("Your Queue > #{appeal.veteran_full_name} > Select Dispositions")
      expect(page).not_to have_content("Select Dispositions > Submit")
    end
  end
end

# rubocop:enable Style/FormatString
