module Naf
  class Configuration
    attr_accessor :api_controller_class,
                  :api_domain_cookie_name,
                  :default_page_options,
                  :expire_cookie,
                  :layout,
                  :log_path,
                  :metric_tags,
                  :metric_send_delay,
                  :model_class,
                  :schema_name,
                  :simple_cluster_authenticator_cookie_expiration_time,
                  :title,
                  :ui_controller_class

    def initialize
      @api_controller_class = "Naf::ApiSimpleClusterAuthenticatorApplicationController"
      @api_domain_cookie_name = "naf_#{Rails.application.class.parent.name.underscore}"
      @default_page_options = [10, 20, 50, 100, 250, 500, 750, 1000, 1500, 2000]
      @expire_cookie = false
      @layout = "naf_layout"
      @metric_tags = ["#{Rails.env}"]
      @metric_send_delay = 120
      @model_class = "::ActiveRecord::Base"
      @simple_cluster_authenticator_cookie_expiration_time = 1.week
      @title = "Naf - a Rails Job Scheduling Engine"
      @ui_controller_class = "::ApplicationController"
    end

  end
end
