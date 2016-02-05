require 'spec_helper'

module Naf
  describe LoggerStyleName do
    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    it { is_expected.to belong_to(:logger_name) }
    it { is_expected.to belong_to(:logger_style) }
    it { is_expected.to belong_to(:logger_level) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { is_expected.to validate_presence_of(:logger_name_id) }
    it { is_expected.to validate_presence_of(:logger_style_id) }

    describe "uniqueness"do
      subject { FactoryGirl.create(:logger_style_name) }
      it { is_expected.to validate_uniqueness_of(:logger_style_id).scoped_to(:logger_name_id) }
    end

  end
end
