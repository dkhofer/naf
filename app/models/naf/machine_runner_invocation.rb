module Naf
  class MachineRunnerInvocation < NafBase
    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    belongs_to :machine_runner,
      class_name: '::Naf::MachineRunner'
    has_many :historical_jobs,
      class_name: '::Naf::HistoricalJob'

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    validates :machine_runner_id,
              :pid, presence: true

    #----------------------
    # *** Class Methods ***
    #++++++++++++++++++++++

    def self.choose(filter)
      if filter.present? && filter == 'top'
        return joins(
          "JOIN (
            SELECT
              machine_runner_id, max(created_at) as created_at
            FROM
              #{::Naf.schema_name}.machine_runner_invocations
            GROUP BY
              machine_runner_id
            ) AS mri2
          ON #{::Naf.schema_name}.machine_runner_invocations.created_at = mri2.created_at AND
            #{::Naf.schema_name}.machine_runner_invocations.machine_runner_id = mri2.machine_runner_id"
        )
      else
        return where({})
      end
    end

    def self.recently_marked_dead(time)
      where("
        #{::Naf.schema_name}.machine_runner_invocations.dead_at IS NOT NULL AND
        #{::Naf.schema_name}.machine_runner_invocations.dead_at > ?", Time.zone.now - time
      )
    end

    #-------------------------
    # *** Instance Methods ***
    #+++++++++++++++++++++++++

    def status
      if self.dead_at.blank?
        if self.wind_down_at.present?
          # Runner is Waiting for jobs to finish running,
          # and will not start any other jobs
          'winding-down'
        else
          'running' # Runner is UP
        end
      else
        'dead' # Runner is DOWN
      end
    end

  end
end
