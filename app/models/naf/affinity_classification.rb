module Naf
  class AffinityClassification < NafBase
    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    has_many :affinities, dependent: :destroy

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    validates :affinity_classification_name, presence: true,
                                             length: { minimum: 1 }

    #-------------------------
    # *** Class Methods ***
    #+++++++++++++++++++++++++

    def self.purpose
      @@purpose ||= find_by_affinity_classification_name('purpose')
    end

    def self.location
      @@location ||= find_by_affinity_classification_name('location')
    end

    def self.application
      @@application ||= find_by_affinity_classification_name('application')
    end

    def self.weight
      @@weight ||= find_by_affinity_classification_name('weight')
    end

    def self.machine
      @@machine ||= find_by_affinity_classification_name('machine')
    end

  end
end
