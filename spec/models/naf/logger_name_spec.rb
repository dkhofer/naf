require 'spec_helper'

module Naf
  describe LoggerName do
    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    it { is_expected.to have_many(:logger_style_names) }
    it { is_expected.to have_many(:logger_styles) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { is_expected.to validate_presence_of(:name) }

    describe "uniqueness"do
      subject { FactoryGirl.create(:logger_name) }
      it { is_expected.to validate_uniqueness_of(:name) }
    end

  end
end
