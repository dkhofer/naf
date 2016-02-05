require 'spec_helper'

module Naf
  describe MachineRunnerInvocation do
    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    it { is_expected.to belong_to(:machine_runner) }
    it { is_expected.to have_many(:historical_jobs) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { is_expected.to validate_presence_of(:machine_runner_id) }
    it { is_expected.to validate_presence_of(:pid) }

    #----------------------
    # *** Class Methods ***
    #++++++++++++++++++++++

    describe "#recently_marked_dead" do
      let!(:invocation) { FactoryGirl.create(:machine_runner_invocation, dead_at: Time.zone.now - 1.hour) }
      before do
        FactoryGirl.create(:machine_runner_invocation, dead_at: Time.zone.now - 40.hours)
      end

      it "return the correct invocation" do
        expect(::Naf::MachineRunnerInvocation.recently_marked_dead(24.hours)).to eq([invocation])
      end
    end

  end
end
