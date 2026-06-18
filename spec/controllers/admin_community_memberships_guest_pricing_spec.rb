require 'rails_helper'

RSpec.describe Admin::CommunityMembershipsController, type: :controller do
  let(:community) { FactoryBot.create(:community) }
  let(:admin_user) { FactoryBot.create(:person, community: community) }
  let(:regular_user) { FactoryBot.create(:person, community: community) }
  let(:admin_membership) { FactoryBot.create(:community_membership, community: community, person: admin_user, admin: true) }
  let(:regular_membership) { FactoryBot.create(:community_membership, community: community, person: regular_user) }

  before do
    @request.host = "#{community.ident}.lvh.me"
    sign_in admin_user
    admin_membership # Create admin membership
  end

  describe "GET #edit" do
    it "builds person_white_label if it doesn't exist" do
      expect(regular_user.person_white_label).to be_nil
      
      get :edit, params: { community_id: community.id, id: regular_membership.id }
      
      expect(response).to have_http_status(:success)
      expect(assigns(:membership).person.person_white_label).to be_present
      expect(assigns(:membership).person.person_white_label.persisted?).to be false
    end

    it "uses existing person_white_label if it exists" do
      existing_white_label = PersonWhiteLabel.create!(person: regular_user, design: 'ladera')
      
      get :edit, params: { community_id: community.id, id: regular_membership.id }
      
      expect(response).to have_http_status(:success)
      expect(assigns(:membership).person.person_white_label).to eq(existing_white_label)
    end
  end

  describe "PATCH #update" do
    context "updating guest_type_pricing_enabled" do
      it "allows enabling guest type pricing" do
        patch :update, params: {
          community_id: community.id,
          id: regular_membership.id,
          community_membership: {
            person_attributes: {
              id: regular_user.id,
              guest_type_pricing_enabled: true,
              person_white_label_attributes: {
                person_id: regular_user.id
              }
            }
          }
        }

        regular_user.reload
        expect(regular_user.guest_type_pricing_enabled?).to be true
      end

      it "allows disabling guest type pricing" do
        regular_user.update!(guest_type_pricing_enabled: true)
        
        patch :update, params: {
          community_id: community.id,
          id: regular_membership.id,
          community_membership: {
            person_attributes: {
              id: regular_user.id,
              guest_type_pricing_enabled: false,
              person_white_label_attributes: {
                person_id: regular_user.id
              }
            }
          }
        }

        regular_user.reload
        expect(regular_user.guest_type_pricing_enabled?).to be false
      end
    end

    context "updating legacy Ladera design" do
      it "allows setting Ladera design" do
        patch :update, params: {
          community_id: community.id,
          id: regular_membership.id,
          community_membership: {
            person_attributes: {
              id: regular_user.id,
              person_white_label_attributes: {
                person_id: regular_user.id,
                design: 'ladera'
              }
            }
          }
        }

        regular_user.reload
        expect(regular_user.person_white_label.design).to eq('ladera')
      end

      it "allows clearing Ladera design" do
        PersonWhiteLabel.create!(person: regular_user, design: 'ladera')
        
        patch :update, params: {
          community_id: community.id,
          id: regular_membership.id,
          community_membership: {
            person_attributes: {
              id: regular_user.id,
              person_white_label_attributes: {
                id: regular_user.person_white_label.id,
                person_id: regular_user.id,
                design: ''
              }
            }
          }
        }

        regular_user.reload
        expect(regular_user.person_white_label.design).to be_blank
      end
    end

    context "updating both profile setting and legacy design" do
      it "allows updating both simultaneously" do
        patch :update, params: {
          community_id: community.id,
          id: regular_membership.id,
          community_membership: {
            person_attributes: {
              id: regular_user.id,
              guest_type_pricing_enabled: true,
              person_white_label_attributes: {
                person_id: regular_user.id,
                design: 'ladera'
              }
            }
          }
        }

        regular_user.reload
        expect(regular_user.guest_type_pricing_enabled?).to be true
        expect(regular_user.person_white_label.design).to eq('ladera')
      end
    end
  end

  describe "Parameter permissions" do
    it "permits guest_type_pricing_enabled parameter" do
      controller_params = {
        community_membership: {
          person_attributes: {
            id: regular_user.id,
            guest_type_pricing_enabled: true
          }
        }
      }

      expect {
        controller.send(:update_params, ActionController::Parameters.new(controller_params))
      }.not_to raise_error
    end
  end
end