module Naf
  class HistoricalJobPrerequisite < ::Naf::ByHistoricalJobId
    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    belongs_to :historical_job,
      class_name: "::Naf::HistoricalJob",
      foreign_key: 'historical_job_id'
    belongs_to :prerequisite_historical_job,
      class_name: "::Naf::HistoricalJob",
      foreign_key: 'prerequisite_historical_job_id'

  end
end
