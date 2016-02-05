require 'spec_helper'

module Naf
  describe MachineRunner do
    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    it { is_expected.to belong_to(:machine) }
    it { is_expected.to have_many(:machine_runner_invocations) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { is_expected.to validate_presence_of(:machine_id) }
    it { is_expected.to validate_presence_of(:runner_cwd) }

    describe "uniqueness"do
      subject { FactoryGirl.create(:machine_runner) }
      it { is_expected.to validate_uniqueness_of(:machine_id).scoped_to(:runner_cwd) }
    end

  end
end
