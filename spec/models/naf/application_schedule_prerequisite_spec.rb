require 'spec_helper'

module Naf
  describe ApplicationSchedulePrerequisite do
    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    it { is_expected.to belong_to(:application_schedule) }
    it { is_expected.to belong_to(:prerequisite_application_schedule) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { is_expected.to validate_presence_of(:prerequisite_application_schedule_id) }

    describe "uniqueness"do
      subject { FactoryGirl.create(:schedule_prerequisite) }
      it { is_expected.to validate_uniqueness_of(:application_schedule_id).scoped_to(:prerequisite_application_schedule_id) }
    end

  end
end
