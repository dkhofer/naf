require 'spec_helper'

module Naf
  describe AffinityClassification do
    # Mass-assignment
    [:affinity_classification_name].each do |a|
      it { should allow_mass_assignment_of(a) }
    end

    [:id,
     :created_at].each do |a|
      it { should_not allow_mass_assignment_of(a) }
    end

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    it { should have_many(:affinities) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { should validate_presence_of(:affinity_classification_name) }

    #----------------------
    # *** Class Methods ***
    #++++++++++++++++++++++

    describe "#purpose" do
      let!(:purpose_affinity_classification) { FactoryGirl.create(:purpose_affinity_classification) }

      it "return the purpose affinity classification" do
        ::Naf::AffinityClassification.purpose.should == purpose_affinity_classification
      end
    end

    describe "#location" do
      let!(:location_affinity_classification) { FactoryGirl.create(:location_affinity_classification) }

      it "return the location affinity classification" do
        ::Naf::AffinityClassification.location.should == location_affinity_classification
      end
    end

    describe "#application" do
      let!(:application_affinity_classification) { FactoryGirl.create(:application_affinity_classification) }

      it "return the application affinity classification" do
        ::Naf::AffinityClassification.application.should == application_affinity_classification
      end
    end

  end
end
