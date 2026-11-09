require "rails_helper"

RSpec.describe "Records from another org can't be reached by id", type: :request do
  let(:casa_org) { create(:casa_org) }
  let(:other_org) { create(:casa_org) }
  let(:admin) { create(:casa_admin, casa_org: casa_org) }

  before { sign_in admin }

  describe "supervisor-volunteer links" do
    let(:own_supervisor) { create(:supervisor, casa_org: casa_org) }
    let(:other_volunteer) { create(:volunteer, casa_org: other_org) }

    it "does not link another org's volunteer" do
      post supervisor_volunteers_path, params: {supervisor_volunteer: {supervisor_id: own_supervisor.id, volunteer_id: other_volunteer.id}},
        headers: {"HTTP_REFERER" => volunteers_path}

      expect(response).to have_http_status(:not_found)
      expect(other_volunteer.reload.supervisor).to be_nil
    end

    it "does not unassign another org's volunteer" do
      other_supervisor = create(:supervisor, casa_org: other_org)
      create(:supervisor_volunteer, supervisor: other_supervisor, volunteer: other_volunteer)

      patch unassign_supervisor_volunteer_path(other_volunteer), headers: {"HTTP_REFERER" => volunteers_path}

      expect(response).to have_http_status(:not_found)
      expect(other_volunteer.reload.supervisor).to eq(other_supervisor)
    end
  end

  describe "checklist items" do
    let(:own_hearing_type) { create(:hearing_type, casa_org: casa_org) }
    let(:other_item) { create(:checklist_item, hearing_type: create(:hearing_type, casa_org: other_org), description: "theirs") }

    it "does not update another org's checklist item through one of our hearing types" do
      patch hearing_type_checklist_item_path(own_hearing_type, other_item), params: {checklist_item: {description: "changed"}}

      expect(response).to have_http_status(:not_found)
      expect(other_item.reload.description).to eq("theirs")
    end
  end

  describe "case groups" do
    let(:own_case) { create(:casa_case, casa_org: casa_org) }
    let(:other_case) { create(:casa_case, casa_org: other_org) }

    it "drops another org's case from a new group" do
      post case_groups_path, params: {case_group: {name: "Siblings", casa_case_ids: [own_case.id, other_case.id]}}

      group = casa_org.case_groups.find_by!(name: "Siblings")
      expect(group.casa_cases).to contain_exactly(own_case)
    end

    it "is rejected by the model too" do
      group = build(:case_group, casa_org: casa_org, casa_cases: [other_case])

      expect(group).not_to be_valid
    end
  end
end
