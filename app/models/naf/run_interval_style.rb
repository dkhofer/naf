module Naf
  class RunIntervalStyle < NafBase
    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    has_many :application_schedules,
      class_name: '::Naf::ApplicationSchedule'

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    validates :name, presence: true

  end
end
