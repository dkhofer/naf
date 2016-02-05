require 'spec_helper'

module Naf
  describe HistoricalJobPrerequisite do
    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    it { is_expected.to belong_to(:historical_job) }
    it { is_expected.to belong_to(:prerequisite_historical_job) }

  end
end
