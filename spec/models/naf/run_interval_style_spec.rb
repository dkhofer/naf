require 'spec_helper'

module Naf
  describe RunIntervalStyle do
    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    it { is_expected.to have_many(:application_schedules) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { is_expected.to validate_presence_of(:name) }

  end
end
