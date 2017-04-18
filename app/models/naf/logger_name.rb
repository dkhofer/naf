module Naf
  class LoggerName < NafBase
    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    has_many :logger_style_names,
      class_name: '::Naf::LoggerStyleName'
    has_many :logger_styles,
      through: :logger_style_names

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    validates :name, uniqueness: true,
                     presence: true

  end
end
