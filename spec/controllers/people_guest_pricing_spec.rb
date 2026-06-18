require 'rails_helper'

RSpec.describe PeopleController, type: :controller do
  let(:community) { FactoryBot.create(:community) }
  let(:user) { FactoryBot.create(:person, community: community) }
  let(:membership) { FactoryBot.create(:community_membership, community: community, person: user) }

  before do
    @request.host = "#{community.ident}.lvh.me"
    sign_in user
    membership # Create membership
  end

  describe "PATCH #update" do
    context "updating guest_type_pricing_enabled" do
      it "allows user to enable guest type pricing" do
        patch :update, params: {
          id: user.username,
          person: {
            guest_type_pricing_enabled: true,
            given_name: user.given_name,
            family_name: user.family_name
          }
        }

        user.reload
        expect(user.guest_type_pricing_enabled?).to be true
        expect(response).to redirect_to(person_path(user))
      end

      it "allows user to disable guest type pricing" do
        user.update!(guest_type_pricing_enabled: true)
        
        patch :update, params: {
          id: user.username,
          person: {
            guest_type_pricing_enabled: false,
            given_name: user.given_name,
            family_name: user.family_name
          }
        }

        user.reload
        expect(user.guest_type_pricing_enabled?).to be false
        expect(response).to redirect_to(person_path(user))
      end

      it "handles checkbox unchecked state (missing parameter)" do
        user.update!(guest_type_pricing_enabled: true)
        
        # Simulate unchecked checkbox (parameter not sent)
        patch :update, params: {
          id: user.username,
          person: {
            given_name: user.given_name,
            family_name: user.family_name
            # guest_type_pricing_enabled not included (unchecked checkbox)
          }
        }

        user.reload
        expect(user.guest_type_pricing_enabled?).to be false
      end
    end

    it "updates other profile fields along with guest type pricing" do
      patch :update, params: {
        id: user.username,
        person: {
          guest_type_pricing_enabled: true,
          given_name: 'Updated Name',
          family_name: 'Updated Family',
          description: 'Updated description'
        }
      }

      user.reload
      expect(user.guest_type_pricing_enabled?).to be true
      expect(user.given_name).to eq('Updated Name')
      expect(user.family_name).to eq('Updated Family')
      expect(user.description).to eq('Updated description')
    end
  end

  describe "Parameter permissions" do
    it "permits guest_type_pricing_enabled parameter" do
      controller_params = {
        person: {
          guest_type_pricing_enabled: true,
          given_name: 'Test',
          family_name: 'User'
        }
      }

      expect {
        controller.send(:person_update_params, ActionController::Parameters.new(controller_params))
      }.not_to raise_error
    end

    it "includes guest_type_pricing_enabled in permitted parameters" do
      controller_params = ActionController::Parameters.new({
        person: {
          guest_type_pricing_enabled: true,
          given_name: 'Test',
          family_name: 'User'
        }
      })

      permitted = controller.send(:person_update_params, controller_params)
      expect(permitted.keys).to include('guest_type_pricing_enabled')
    end
  end
end