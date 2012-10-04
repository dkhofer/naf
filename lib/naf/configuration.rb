module Naf

  class Configuration
    attr_accessor :schema_name, :model_class, :controller_class, :title, :papertrail_group_id, :job_refreshing
    
    def initialize
      @model_class = "::ActiveRecord::Base"
      @controller_class = "::ApplicationController"
      @title = "Naf - a Rails Job Scheduling Engine"
      @papertrail_group_id = nil
      @job_refreshing = false
    end

  end

end
