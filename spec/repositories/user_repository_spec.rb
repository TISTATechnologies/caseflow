describe UserRepository do
  before do
    FeatureToggle.enable!(:test_facols)
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  let(:css_id) { "TEST1" }

  context ".vacols_role" do
    subject { UserRepository.user_info_from_vacols(css_id)[:roles] }

    context "when a user is an attorney" do
      let!(:staff) { create(:staff, sattyid: "1234", sdomainid: css_id) }

      it "should return an attorney role" do
        expect(subject).to eq ["attorney"]
      end
    end

    context "when a user is a judge" do
      let!(:staff) { create(:staff, svlj: "J", sdomainid: css_id) }

      it "should return a judge role" do
        expect(subject).to eq ["judge"]
      end
    end

    context "when a user is an acting judge" do
      let!(:staff) { create(:staff, svlj: "A", sdomainid: css_id) }

      it "should return a judge role" do
        expect(subject).to eq ["judge"]
      end
    end

    context "when a user is a co-located admin" do
      let!(:staff) { create(:staff, stitle: "A1", sdomainid: css_id) }

      it "should return a co-located role" do
        expect(subject).to eq ["colocated"]
      end
    end

    context "when a user is an acting judge and has an attorney number" do
      let!(:staff) { create(:staff, svlj: "A", sattyid: "1234", sdomainid: css_id) }

      it "should return both roles" do
        expect(subject).to eq %w[attorney judge]
      end
    end

    context "when a user is neither" do
      let!(:staff) { create(:staff, svlj: "L", sdomainid: css_id) }

      it "should not return a role" do
        expect(subject).to eq []
      end
    end

    context "when user does not exist in VACOLS" do
      it "should return nil" do
        expect(subject).to eq []
      end
    end
  end

  context "can_access_task?" do
    subject { UserRepository.can_access_task?(css_id, "4321") }

    context "when a task is assigned to a user" do
      let(:user) { User.create(css_id: css_id, station_id: "101") }
      let!(:vacols_case) { create(:case, :assigned, bfkey: "4321", user: user) }

      it "should return true" do
        expect(subject).to eq true
      end
    end

    context "when a task is not assigned to a user" do
      let(:user) { User.create(css_id: css_id, station_id: "101") }
      let!(:vacols_case) { create(:case, :assigned, bfkey: "5678", user: user) }

      it "should raise Caseflow::Error::UserRepositoryError" do
        expect { subject }.to raise_error(Caseflow::Error::UserRepositoryError)
      end
    end
  end

  context "vacols_uniq_id" do
    subject { UserRepository.user_info_from_vacols(css_id)[:uniq_id] }

    context "when user exists in VACOLS" do
      let!(:staff) { create(:staff, slogid: "LKG564", sdomainid: css_id) }

      it "should return an ID" do
        expect(subject).to eq "LKG564"
      end
    end

    context "when user does not exist in VACOLS" do
      it "should return nil" do
        expect(subject).to eq nil
      end
    end
  end
end
