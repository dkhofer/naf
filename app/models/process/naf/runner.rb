require 'timeout'

module Process::Naf
  class Runner < ::Af::Application

    #----------------
    # *** Options ***
    #+++++++++++++++++

    opt :wait_time_for_processes_to_terminate,
        "time between askign processes to terminate and sending kill signals",
        argument_note: "SECONDS",
        default: 120
    opt :check_schedules_period,
        "time between checking schedules",
        argument_note: "MINUTES",
        default: 1
    opt :schedule_fudge_scale,
        "amount of time to look back in schedule for run_start_minute schedules (scaled to --check-schedule-period)",
        default: 5
    opt :runner_stale_period,
        "amount of time to consider a machine out of touch if it hasn't updated its machine entry",
        argument_note: "MINUTES",
        default: 10
    opt :loop_sleep_time,
        "runner main loop sleep time",
        argument_note: "SECONDS",
        default: 30
    opt :server_address,
        "set the machines server address (dangerous)",
        type: :string,
        default: ::Naf::Machine.machine_ip_address,
        hidden: true
    opt :maximum_memory_usage,
        "percentage of memory used which will limit  process spawning",
        default: 85.0,
        argument_note: "PERCENT"
    opt :disable_gc_modifications,
        "don't modify ruby GC parameters",
        default: false

    def initialize
      super
      opt :log_configuration_files, default: ["af.yml",
                                              "af-#{Rails.env}.yml",
                                              "naf.yml",
                                              "naf-#{Rails.env}.yml",
                                              "nafrunner.yml",
                                              "nafrunner-#{Rails.env}.yml",
                                              "#{af_name}.yml",
                                              "#{af_name}-#{Rails.env}.yml"]
      @last_machine_log_level = nil
      @job_creator = ::Logical::Naf::JobCreator.new
    end

    def work
      unless @disable_gc_modifications
        # These configuration changes will help forked processes, not the runner
        ENV['RUBY_HEAP_MIN_SLOTS'] = '500000'
        ENV['RUBY_HEAP_SLOTS_INCREMENT'] = '250000'
        ENV['RUBY_HEAP_SLOTS_GROWTH_FACTOR'] = '1'
        ENV['RUBY_GC_MALLOC_LIMIT'] = '50000000'
      end

      machine = ::Naf::Machine.find_by_server_address(@server_address)

      unless machine.present?
        logger.fatal "This machine is not configued correctly (ipaddress: #{@server_address})."
        logger.fatal "Please update #{::Naf::Machine.table_name} with an entry for this machine."
        logger.fatal "Exiting..."
        exit 1
      end

      if machine.try_lock_for_runner_use
        begin
          work_machine(machine)
        ensure
          machine.unlock_for_runner_use
        end
      else
        logger.fatal "There is already a runner running on this machine, exiting..."
        exit 1
      end
    end

    def work_machine(machine)
      machine.mark_alive
      machine.mark_up

      # Make sure no processes are thought to be running on this machine
      terminate_old_processes(machine)

      logger.info "working: #{machine}"

      @children = {}

      at_exit {
        ::Af::Application.singleton.emergency_teardown
      }

      @job_fetcher = ::Logical::Naf::JobFetcher.new(machine)

      while true
        break unless work_machine_loop(machine)
        GC.start
      end

      logger.info "runner quitting"
    end

    def work_machine_loop(machine)
      machine.reload

      # Check machine status
      if !machine.enabled
        logger.warn "this machine is disabled #{machine}"
        return false
      elsif machine.marked_down
        logger.warn "this machine is marked down #{machine}"
        return false
      end

      machine.mark_alive

      if machine.log_level != @last_machine_log_level
        @last_machine_log_level = machine.log_level
        unless @last_machine_log_level.blank?
          logging_configurator.parse_and_set_logger_levels(@last_machine_log_level)
        end
      end

      check_schedules(machine)

      # clean up children that have exited
      logger.detail "cleaning up dead children: #{@children.length}"

      if @children.length > 0
        while @children.length > 0
          pid = nil
          status = nil
          begin
            Timeout::timeout(@loop_sleep_time) do
              pid, status = Process.waitpid2(-1)
            end
          rescue Timeout::Error
            # XXX is there a race condition where a child process exits
            # XXX has not set pid or status yet and timeout fires?
            # XXX i bet there is
            # XXX so this code is here:
            dead_children = []
            @children.each do |pid, child|
              unless is_job_process_alive?(child)
                dead_children << child
              end
            end

            unless dead_children.blank?
              logger.error "dead children even with timeout during waitpid2(): #{dead_children.inspect}"
              logger.error "this isn't necessarily incorrect -- look for the pids to be cleaned up next round, if not: call it a bug"
            end

            break
          rescue Errno::ECHILD => e
            logger.error "No child when we thought we had children #{@children.inspect}"
            logger.error e
            pid = @children.first.try(:first)
            status = nil
            logger.error "pulling first child off list to clean it up: pid=#{pid}"
          end

          if pid
            begin
              child_job = @children.delete(pid)
              # Update job tags
              child_job.historical_job.remove_tags([::Naf::HistoricalJob::SYSTEM_TAGS[:work]])
              child_job.historical_job.add_tags([::Naf::HistoricalJob::SYSTEM_TAGS[:cleanup]])

              if child_job.present?
                if status.nil? || status.exited? || status.signaled?
                  logger.info { "cleaning up dead child: #{child_job.reload}" }
                  finish_job(child_job,
                             { exit_status: (status && status.exitstatus), termination_signal: (status && status.termsig) })

                  # Update jog tags
                  child_job.historical_job.remove_tags([::Naf::HistoricalJob::SYSTEM_TAGS[:cleanup]])
                else
                  # this can happen if the child is sigstopped
                  logger.warn "child waited for did not exit: #{child_job}, status: #{status.inspect}"
                end
              else
                # XXX ERROR no child for returned pid -- this can't happen
                logger.warn "child pid: #{pid}, status: #{status.inspect}, not managed by this runner"
              end
            rescue StandardError => e
              # XXX just incase a job control failure -- more code here
              logger.error "some failure during child clean up"
              logger.error e
            end
          end
        end
      else
        logger.detail "sleeping in loop: #{@loop_sleep_time} seconds"
        sleep(@loop_sleep_time)
      end

      # start new jobs
      logger.detail "starting new jobs, num children: #{@children.length}/#{machine.thread_pool_size}"
      while @children.length < machine.thread_pool_size && memory_available_to_spawn?
        logger.debug_gross "fetching jobs because: children: #{@children.length} < #{machine.thread_pool_size} (poolsize)"
        begin
          running_job = @job_fetcher.fetch_next_job

          unless running_job.present?
            logger.debug_gross "no more jobs to run"
            break
          end

          logger.info "starting new job : #{running_job}"

          pid = running_job.historical_job.spawn
          if pid
            @children[pid] = running_job
            running_job.pid = pid
            running_job.historical_job.pid = pid
            running_job.historical_job.failed_to_start = false
            logger.info "job started : #{running_job}"
            running_job.save!
            running_job.historical_job.save!
          else
            # should never get here (well, hopefully)
            logger.error "failed to execute #{running_job}"
            # Update job tags
            running_job.historical_job.remove_all_tags
            running_job.historical_job.add_tags([::Naf::HistoricalJob::SYSTEM_TAGS[:cleanup]])

            finish_job(running_job, { failed_to_start: true })

            # Update job tags
            running_job.historical_job.remove_tags([::Naf::HistoricalJob::SYSTEM_TAGS[:cleanup]])
          end
        rescue StandardError => e
          # XXX rescue for various issues
          logger.error "failure during job start"
          logger.error e
        end
      end
      logger.debug_gross "done starting jobs"

      return true
    end

    def check_schedules(machine)
      if ::Naf::Machine.is_it_time_to_check_schedules?(@check_schedules_period.minutes)
        logger.debug "it's time to check schedules"
        if ::Naf::ApplicationSchedule.try_lock_schedules
          logger.debug_gross "checking schedules"
          machine.mark_checked_schedule
          ::Naf::ApplicationSchedule.unlock_schedules

          # check scheduled tasks
          should_be_queued.each do |application_schedule|
            logger.info "scheduled application: #{application_schedule}"
            begin
              Range.new(0, application_schedule.application_run_group_limit || 1, true).each do
                @job_creator.queue_application_schedule(application_schedule)
              end
            rescue ::Naf::HistoricalJob::JobPrerequisiteLoop => jpl
              logger.error "couldn't queue schedule because of prerequisite loop: #{jpl.message}"
              logger.error jpl
              application_schedule.enabled = false
              application_schedule.save!
              logger.alarm "Application Schedule disabled due to loop: #{application_schedule}"
            end
          end

          # check the runner machines
          ::Naf::Machine.enabled.up.each do |runner_to_check|
            if runner_to_check.is_stale?(@runner_stale_period.minutes)
              logger.alarm "runner is stale for #{@runner_stale_period} minutes, #{runner_to_check}"
              runner_to_check.mark_machine_down(machine)
            end
          end
        end
      end
    end

    # XXX update_all doesn't support "from_partition" so we have this helper
    def update_historical_job(updates, historical_job_id)
      updates[:updated_at] = Time.zone.now
      update_columns = updates.map{ |k,v| "#{k} = ?" }.join(", ")
      update_sql = <<-SQL
        UPDATE
          #{::Naf::HistoricalJob.partition_table_name(historical_job_id)}
        SET
          #{update_columns}
        WHERE
          id = ?
      SQL
      ::Naf::HistoricalJob.find_by_sql([update_sql] + updates.values + [historical_job_id])
    end

    def finish_job(running_job, updates = {})
      ::Naf::HistoricalJob.transaction do
        update_historical_job(updates.merge({ finished_at: Time.zone.now }), running_job.id)
        running_job.delete
      end
    end

    # kill(0, pid) seems to fail during at_exit block
    # so this shoots from the hip
    def emergency_teardown
      return if @children.length == 0
      logger.warn "emergency teardown of #{@children.length} job(s)"
      @children.clone.each do |pid, child|
        send_signal_and_maybe_clean_up(child, "TERM")
      end
      sleep(2)
      @children.clone.each do |pid, child|
        send_signal_and_maybe_clean_up(child, "KILL")

        # Update job tags
        child.historical_job.remove_all_tags
        child.historical_job.add_tags([::Naf::HistoricalJob::SYSTEM_TAGS[:cleanup]])

        # force job down
        finish_job(child)

        # Update job tags
        child.historical_job.remove_tags([::Naf::HistoricalJob::SYSTEM_TAGS[:cleanup]])
      end
    end

    def terminate_old_processes(machine)
      # check if any processes are hanging around and ask them
      # politely if they will please terminate
      jobs = assigned_jobs(machine)
      if jobs.length == 0
        logger.detail "no jobs to remove"
        return
      end
      logger.info "number of old jobs to sift through: #{jobs.length}"
      jobs.each do |job|
        logger.detail "job still around: #{job}"
        if job.request_to_terminate == false
          logger.warn "politely asking process: #{job.pid} to terminate itself"
          job.request_to_terminate = true
          job.save!
        end
      end

      # wait
      (1..@wait_time_for_processes_to_terminate).each do |i|
        num_assigned_jobs = assigned_jobs(machine).length
        return if num_assigned_jobs == 0
        logger.debug_medium "#{i}/#{@wait_time_for_processes_to_terminate}: sleeping 1 second while we wait for " +
          "#{num_assigned_jobs} assigned job(s) to terminate as requested"
        sleep(1)
      end

      # nudge them to terminate
      jobs = assigned_jobs(machine)
      if jobs.length == 0
        logger.debug_gross "assigned jobs have exited after asking to terminate nicely"
        return
      end
      jobs.each do |job|
        logger.warn "sending SIG_TERM to process: #{job}"
        send_signal_and_maybe_clean_up(job, "TERM")
      end

      # wait
      (1..5).each do |i|
        num_assigned_jobs = assigned_jobs(machine).length
        return if num_assigned_jobs == 0
        logger.debug_medium "#{i}/5: sleeping 1 second while we wait for #{num_assigned_jobs} assigned job(s) to terminate from SIG_TERM"
        sleep(1)
      end

      # kill with fire
      assigned_jobs(machine).each do |job|
        logger.alarm "sending SIG_KILL to process: #{job}"
        send_signal_and_maybe_clean_up(job, "KILL")

        # Update job tags
        job.historical_job.remove_all_tags
        job.historical_job.add_tags([::Naf::HistoricalJob::SYSTEM_TAGS[:cleanup]])

        # job force job down
        finish_job(job)

        # Update job tags
        job.historical_job.remove_tags([::Naf::HistoricalJob::SYSTEM_TAGS[:cleanup]])
      end
    end

    def send_signal_and_maybe_clean_up(job, signal)
      if job.pid.nil?
        # Update job tags
        job.historical_job.remove_all_tags
        job.historical_job.add_tags([::Naf::HistoricalJob::SYSTEM_TAGS[:cleanup]])

        finish_job(job)

        # Update job tags
        job.historical_job.remove_tags([::Naf::HistoricalJob::SYSTEM_TAGS[:cleanup]])

        return false
      end

      begin
        retval = Process.kill(signal, job.pid)
        logger.detail "#{retval} = kill(#{signal}, #{job.pid})"
      rescue Errno::ESRCH
        logger.detail "ESRCH = kill(#{signal}, #{job.pid})"

        # Update job tags
        job.historical_job.remove_all_tags
        job.historical_job.add_tags([::Naf::HistoricalJob::SYSTEM_TAGS[:cleanup]])

        # job does not exist -- mark it finished
        finish_job(job)

        # Update job tags
        job.historical_job.remove_tags([::Naf::HistoricalJob::SYSTEM_TAGS[:cleanup]])

        return false
      end
      return true
    end

    def is_job_process_alive?(job)
      return send_signal_and_maybe_clean_up(job, 0)
    end

    def assigned_jobs(machine)
      return ::Naf::RunningJob.assigned_jobs(machine).select do |job|
        is_job_process_alive?(job)
      end
    end

    def should_be_queued
      not_finished_applications = ::Naf::HistoricalJob.
        queued_between(Time.zone.now - Naf::HistoricalJob::JOB_STALE_TIME, Time.zone.now).
        where("finished_at IS NULL AND request_to_terminate = false").
        find_all{ |job| job.application_id.present? }.
        index_by{ |job| job.application_id }

      application_last_runs = ::Naf::HistoricalJob.application_last_runs.
        index_by{ |job| job.application_id }

      # find the run_interval based schedules that should be queued
      # select anything that isn't currently running and completed
      # running more than run_interval minutes ago
      relative_schedules_what_need_queuin = ::Naf::ApplicationSchedule.where(enabled: true).relative_schedules.select do |schedule|
        (not_finished_applications[schedule.application_id].nil? &&
          (application_last_runs[schedule.application_id].nil? ||
            (Time.zone.now - application_last_runs[schedule.application_id].finished_at) > (schedule.run_interval.minutes)))
      end

      # find the run_start_minute based schedules
      # select anything that
      #  isn't currently running (or queued) AND
      #  hasn't run since run_start_time AND
      #  should have been run by now AND
      #  that should have run within fudge period AND
      exact_schedules_what_need_queuin = ::Naf::ApplicationSchedule.where(enabled: true).exact_schedules.select do |schedule|
        (not_finished_applications[schedule.application_id].nil? &&
          (application_last_runs[schedule.application_id].nil? ||
            ((Time.zone.now.to_date + schedule.run_start_minute.minutes) >= application_last_runs[schedule.application_id].finished_at)) &&
          (Time.zone.now - (Time.zone.now.to_date + schedule.run_start_minute.minutes)) >= 0.seconds &&
          ((Time.zone.now - (Time.zone.now.to_date + schedule.run_start_minute.minutes)) <= (@check_schedules_period * @schedule_fudge_scale).minutes)
        )
      end

      return relative_schedules_what_need_queuin + exact_schedules_what_need_queuin
    end

    def memory_available_to_spawn?
      begin
        m = MemInfo.new
        memory_used = (m.memused.to_f / m.memtotal)
      rescue
        return true
      end

      if memory_used < @maximum_memory_usage
        logger.detail "memory available: #{memory_used} (used) < #{@maximum_memory_usage} (max percent)"
        return true
      end
      logger.info "not enough memory to spawn: #{memory_used} (used) < #{@maximum_memory_usage} (max percent)"

      return false
    end

  end
end
