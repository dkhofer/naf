module Naf
  class JobsController < Naf::ApplicationController

    include Naf::ApplicationHelper

    before_filter :set_cols_and_attributes

    def index
      respond_to do |format|
        format.html do
        end
        format.json do
          @jobs = []
          job =[]
          Logical::Naf::Job.search(params[:search]).map(&:to_hash).map do |hash|
            add_urls(hash).map do |key, value|
              value ||= ''
              job << value
            end
            @jobs << job
            job = []
          end
          render :layout => 'naf/layouts/jquery_datatables'
        end
      end
    end

    def show
      @record = Naf::Job.find(params[:id])
      @record = Logical::Naf::Job.new(@record)
      respond_to do |format|
        format.json do
          render :json => {:cols => @attributes, :job => @record.to_detailed_hash}.to_json
        end
        format.html do
          render :template => 'naf/record'
        end
      end
    end

    def new
    end

    def create
     @job = Naf::Job.new(params[:job])
     if params[:job][:application_id] and app = Naf::Application.find(params[:job][:application_id])
       @job.command = app.command
       @job.application_type_id = app.application_type_id
       schedule = app.application_schedule
       @job.application_run_group_restriction_id = schedule ? schedule.application_run_group_restriction_id : Naf::ApplicationRunGroupRestriction::NO_RESTRICTIONS
       @job.application_run_group_name = schedule ? schedule.application_run_group_name : "Manually Enqueued Group"
       post_source = "Application: #{app.title}"
     else
       post_source = "Job"
     end
      respond_to do |format|
        format.json do
          response = {}
          if @job.save
            response[:job_url] = url_for(@job)
            response[:post_source] = post_source
            response[:saved] = true
          else
            response[:saved] = false
            response[:errors] = @job.errors.full_messages
          end
          puts response
          render :json => response.to_json
        end
      end
    end

    def edit
      @job = Naf::Job.find(params[:id])
    end

    def update
      respond_to do |format|
        @job = Naf::Job.find(params[:id])
        if @job.update_attributes(params[:job])
          format.html do
            redirect_to(@job, :notice => 'Job was successfully updated.') 
          end
          format.json do
            render :json => {:success => true}.to_json
          end
        else
          format.html do 
            render :action => "edit"
          end
          format.json do
            render :json => {:success => false}.to_json
          end
        end
      end
    end


    private

    def set_cols_and_attributes
      @attributes = Logical::Naf::Job::ATTRIBUTES
      @cols = Logical::Naf::Job::COLUMNS
    end

    def add_urls(hash)
      job = ::Naf::Job.find(hash[:id])
      if application = job.application
        hash[:application_url] = url_for(application)
      else
        hash[:application_url] = nil
      end
      hash[:papertrail_url] = papertrail_link(job)
      return hash
    end

  end

end
