
require 'spec_helper'

module Naf
  describe LoggerLevel do
    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    it { is_expected.to have_many(:logger_style_names) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { is_expected.to validate_presence_of(:level) }

    describe "uniqueness"do
      subject { FactoryGirl.create(:logger_level) }
      it { is_expected.to validate_uniqueness_of(:level) }
    end

  end
end
