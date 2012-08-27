module Naf
  class JobAffinityTab < NafBase
    validates :job_id, :affinity_id, :presence => true

    validates_uniqueness_of :affinity_id, :scope => :job_id, :message => "has already been taken for this job"

    belongs_to :job, :class_name => "::Naf::Job"
    belongs_to :affinity, :class_name => "::Naf::Affinity"

    delegate :title, :script_type_name, :command, :to => :job
    delegate :affinity_name, :to => :affinity

    delegate :affinity_classification_name, :to => :affinity

    attr_accessible :job_id, :affinity_id
  end
end