module Naf
  class ApplicationSchedulePrerequisite < ::Naf::NafBase
    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    belongs_to :application_schedule,
      class_name: "::Naf::ApplicationSchedule"
    belongs_to :prerequisite_application_schedule,
      class_name: "::Naf::ApplicationSchedule"

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    validates :prerequisite_application_schedule_id, presence: true
    validates :application_schedule_id, uniqueness: {
                                          scope: :prerequisite_application_schedule_id
                                        }

    def self.pickleables(pickler)
			return self.joins([application_schedule: :application]).
				where('applications.deleted = false').
				where(
					"NOT EXISTS(
					   SELECT
						   1
						 FROM
						   #{::Naf.schema_name}.application_schedules AS a_s
						 WHERE
						   application_schedule_prerequisites.prerequisite_application_schedule_id = a_s.id AND
						 EXISTS(
						   SELECT
							   1
							 FROM
							   #{::Naf.schema_name}.applications AS a
							 WHERE
							   a_s.application_id = a.id AND
								   deleted IS TRUE
						 )
					)"
				)
    end

  end
end
