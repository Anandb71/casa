require "rails_helper"

RSpec.describe UiHelper, type: :helper do
  describe "#grouped_options_for_assigning_case" do
    before do
      @casa_case = create(:casa_case)
      @volunteer = create(:volunteer, casa_org: @casa_case.casa_org)
      current_user = create(:supervisor)
      allow(helper).to receive(:current_user).and_return(current_user)
    end

    it "does not render duplicate casa_case" do
      options = helper.grouped_options_for_assigning_case(@volunteer)

      expect(options[0]).to eq(options[0].uniq { |option| option[0] })
      expect(options[1]).to eq(options[1].uniq { |option| option[0] })
    end

    context "with reassigned case" do
      it "shows reassigned case only in Assigned group" do
        volunteer_a = create(:volunteer, casa_org: @casa_case.casa_org)
        volunteer_b = create(:volunteer, casa_org: @casa_case.casa_org)
        reassigned_case = create(:casa_case, casa_org: @casa_case.casa_org)

        create(:case_assignment, casa_case: reassigned_case, volunteer: volunteer_a, active: false)
        create(:case_assignment, casa_case: reassigned_case, volunteer: volunteer_b, active: true)

        options = helper.grouped_options_for_assigning_case(@volunteer)
        not_assigned_group = options[0][1]
        assigned_group = options[1][1]

        not_assigned_case_ids = not_assigned_group.map { |option| option[1] }
        assigned_case_ids = assigned_group.map { |option| option[1] }

        expect(not_assigned_case_ids).not_to include(reassigned_case.id)
        expect(assigned_case_ids).to include(reassigned_case.id)
      end

      it "shows case with only inactive assignment in Not Assigned group" do
        volunteer_a = create(:volunteer, casa_org: @casa_case.casa_org)
        inactive_only_case = create(:casa_case, casa_org: @casa_case.casa_org)

        create(:case_assignment, casa_case: inactive_only_case, volunteer: volunteer_a, active: false)

        options = helper.grouped_options_for_assigning_case(@volunteer)
        not_assigned_group = options[0][1]
        assigned_group = options[1][1]

        not_assigned_case_ids = not_assigned_group.map { |option| option[1] }
        assigned_case_ids = assigned_group.map { |option| option[1] }

        expect(not_assigned_case_ids).to include(inactive_only_case.id)
        expect(assigned_case_ids).not_to include(inactive_only_case.id)
      end

      it "shows never assigned case in Not Assigned group" do
        never_assigned_case = create(:casa_case, casa_org: @casa_case.casa_org)

        options = helper.grouped_options_for_assigning_case(@volunteer)
        not_assigned_group = options[0][1]
        assigned_group = options[1][1]

        not_assigned_case_ids = not_assigned_group.map { |option| option[1] }
        assigned_case_ids = assigned_group.map { |option| option[1] }

        expect(not_assigned_case_ids).to include(never_assigned_case.id)
        expect(assigned_case_ids).not_to include(never_assigned_case.id)
      end
    end
  end
end
