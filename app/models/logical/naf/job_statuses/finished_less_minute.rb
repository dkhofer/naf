module Logical
  module Naf
    module JobStatuses
      class FinishedLessMinute

        def self.all(conditions)
          <<-SQL
            (SELECT j.*, null AS "historical_job_id"
              FROM "#{::Naf.schema_name}"."historical_jobs" AS j
              WHERE j.finished_at > '#{Time.zone.now - 1.minute}'
              #{conditions}
              ORDER BY finished_at desc)
          SQL
        end

      end
    end
  end
end