require 'rails_helper'

RSpec.describe PersonWhiteLabel, type: :model do
  let(:community) { FactoryBot.create(:community) }
  let(:person) { FactoryBot.create(:person, community: community) }
  let(:white_label) { PersonWhiteLabel.create!(person: person) }

  describe "Guest type pricing methods" do
    describe "#ladera_enabled?" do
      context "when design is 'ladera'" do
        before { white_label.update!(design: 'ladera') }

        it "returns true" do
          expect(white_label.ladera_enabled?).to be true
        end
      end

      context "when design is nil" do
        before { white_label.update!(design: nil) }

        it "returns false" do
          expect(white_label.ladera_enabled?).to be false
        end
      end

      context "when design is something else" do
        before { white_label.update!(design: 'other_design') }

        it "returns false" do
          expect(white_label.ladera_enabled?).to be false
        end
      end
    end

    describe ".ladera_users" do
      let!(:ladera_person1) { FactoryBot.create(:person, community: community) }
      let!(:ladera_person2) { FactoryBot.create(:person, community: community) }
      let!(:regular_person) { FactoryBot.create(:person, community: community) }

      before do
        PersonWhiteLabel.create!(person: ladera_person1, design: 'ladera')
        PersonWhiteLabel.create!(person: ladera_person2, design: 'ladera')
        PersonWhiteLabel.create!(person: regular_person, design: nil)
      end

      it "returns only users with Ladera design" do
        ladera_users = PersonWhiteLabel.ladera_users
        expect(ladera_users.count).to eq(2)
        expect(ladera_users.map(&:person)).to match_array([ladera_person1, ladera_person2])
      end
    end

    describe ".enable_ladera_for_user" do
      context "when user has no existing PersonWhiteLabel" do
        it "creates a new PersonWhiteLabel with Ladera design" do
          expect {
            PersonWhiteLabel.enable_ladera_for_user(person.id)
          }.to change { PersonWhiteLabel.count }.by(1)

          person.reload
          expect(person.person_white_label.design).to eq('ladera')
        end
      end

      context "when user has existing PersonWhiteLabel" do
        before { PersonWhiteLabel.create!(person: person, design: nil) }

        it "updates the existing PersonWhiteLabel to Ladera design" do
          expect {
            PersonWhiteLabel.enable_ladera_for_user(person.id)
          }.not_to change { PersonWhiteLabel.count }

          person.reload
          expect(person.person_white_label.design).to eq('ladera')
        end
      end
    end

    describe ".disable_ladera_for_user" do
      context "when user has PersonWhiteLabel with Ladera design" do
        before { PersonWhiteLabel.create!(person: person, design: 'ladera') }

        it "sets design to nil" do
          PersonWhiteLabel.disable_ladera_for_user(person.id)
          person.reload
          expect(person.person_white_label.design).to be_nil
        end
      end

      context "when user has no PersonWhiteLabel" do
        it "does nothing and doesn't raise error" do
          expect {
            PersonWhiteLabel.disable_ladera_for_user(person.id)
          }.not_to raise_error
        end
      end
    end
  end

  describe "#show method integration" do
    context "when design is ladera" do
      before { white_label.update!(design: 'ladera') }

      it "includes no_top_search as true using ladera_enabled? method" do
        result = white_label.show
        expect(result[:no_top_search]).to be true
      end
    end

    context "when design is not ladera" do
      before { white_label.update!(design: nil) }

      it "includes no_top_search as false using ladera_enabled? method" do
        result = white_label.show
        expect(result[:no_top_search]).to be false
      end
    end
  end
end