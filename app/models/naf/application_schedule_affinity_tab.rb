module Naf
  class ApplicationScheduleAffinityTab < NafBase
    validates :application_schedule_id, :affinity_id, :presence => true

    validates_uniqueness_of :affinity_id, :scope => :application_schedule_id, :message => "has already been taken for this script"

    belongs_to :application_schedule, :class_name => '::Naf::ApplicationSchedule'

    belongs_to :affinity, :class_name => '::Naf::Affinity'

    delegate :affinity_name, :affinity_classification_name, :to => :affinity

    attr_accessible :application_schedule_id, :affinity_id

    def script_title
      application_schedule.title
    end

    def application
      if schedule = application_schedule
        application_schedule.application
      else
        nil
      end
    end

    def self.pickleables(pickler)
      self.joins([application_schedule: :application]).
        where('applications.deleted = false')
    end

  end
end
