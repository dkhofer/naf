module Naf
  class Application < NafBase
    validates :application_type_id, :command, :title, :presence => true
    validates :title, :uniqueness => true
    validates :short_name, :uniqueness => true, :allow_blank => true,
              :format => { :with => /^[a-zA-Z_][a-zA-Z0-9_]*$/,
                           :message => "letters should be first" }
    before_save :check_short_name
    attr_accessible :title, :command, :application_type_id, :log_level, :application_schedule_attributes, :short_name

    has_one :application_schedule, :class_name => '::Naf::ApplicationSchedule', :dependent => :destroy
    belongs_to :application_type, :class_name => '::Naf::ApplicationType'
    delegate :script_type_name, :to => :application_type

    accepts_nested_attributes_for :application_schedule, :allow_destroy => true

    def to_s
      components = []
      if deleted
        components << "DELETED"
      end
      components << "id: #{id}"
      components << title
      return "::Naf::Application<#{components.join(', ')}>"
    end

    def last_queued_job
      last_queued_job = Naf::Job.recently_queued
        .where(:application_id => self.id)
        .group("application_id")
        .select("application_id, max(id) as id").first
      last_queued_job ? Naf::Job.find(last_queued_job.id) : nil
    end

    def short_name_if_it_exist
      short_name || title
    end

    private

    def check_short_name
      self.short_name = nil if self.short_name.blank?
    end
  end
end
