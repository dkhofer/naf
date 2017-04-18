module Naf
  class LoggerLevel < NafBase
    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    has_many :logger_style_names,
      class_name: '::Naf::LoggerStyleName'

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    validates :level, uniqueness: true,
                      presence: true

  end
end
