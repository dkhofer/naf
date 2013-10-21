require 'aws'

module Logical
  module Naf
    class LogReader

      NAF_DATABASE_HOSTNAME = Rails.configuration.database_configuration[Rails.env]['host'].present? ?
        Rails.configuration.database_configuration[Rails.env]['host'] : 'localhost'
      NAF_DATABASE = Rails.configuration.database_configuration[Rails.env]['database']
      NAF_SCHEMA = ::Naf.schema_name
      NAF_LOG_PATH = "#{::Naf::LOGGING_ROOT_DIRECTORY}/naflogs/#{NAF_DATABASE_HOSTNAME}/#{NAF_DATABASE}/#{NAF_SCHEMA}/jobs/"
      DATE_REGEX = /((\d){4}-(\d){2}-(\d){2} (\d){2}:(\d){2}:(\d){2} UTC)/

      def log_files
        tree = bucket.objects.with_prefix(prefix).as_tree
        directories = tree.children.select(&:branch?).collect(&:prefix).uniq

        files = []
        directories.each do |directory|
          tree = bucket.objects.with_prefix(directory).as_tree
          tree.children.select(&:leaf?).collect(&:key).each do |file|
            files << file
          end
        end
        files = sort_files(files)

        return files
      end

      def runner_log_files(runner_id)
        @runner_id = runner_id
        tree = bucket.objects.with_prefix(prefix).as_tree
        directories = tree.children.select(&:branch?).collect(&:prefix).uniq

        files = []
        directories.each do |directory|
          tree = bucket.objects.with_prefix(directory).as_tree
          tree.children.select(&:leaf?).collect(&:key).each do |file|
            files << file
          end
        end
        files = sort_files(files)

        return files
      end


      def retrieve_file(file)
        bucket.objects[file].read
      end

      def retrieve_job_files(job_id)
        tree = bucket.objects.with_prefix(prefix + "#{job_id}").as_tree
        tree.children.select(&:leaf?).collect(&:key)
      end

      private

      def s3
        # Use AWS credentials to access S3
        @s3 ||= AWS::S3.new(access_key_id: AWS_ID,
                            secret_access_key: AWS_KEY,
                            ssl_verify_peer: false)
      end

      def bucket
        @bucket ||= s3.buckets[NAF_BUCKET]
      end

      def prefix
        if @runner_id.present?
          "naf/#{project_name}/#{Rails.env}/#{creation_time}/naflogs/#{NAF_DATABASE_HOSTNAME}/#{NAF_DATABASE}/#{NAF_SCHEMA}/runners/#{@runner_id}/invocations/"
        else
          "naf/#{project_name}/#{Rails.env}/#{creation_time}/naflogs/#{NAF_DATABASE_HOSTNAME}/#{NAF_DATABASE}/#{NAF_SCHEMA}/jobs/"
        end
      end

      def sort_files(files)
        files.sort do |x, y|
          -Time.parse(x.scan(/\d{4}-.*UTC/).first).to_i <=> -Time.parse(y.scan(/\d{4}-.*UTC/).first).to_i
        end
      end

    	def project_name
    		(`git remote -v`).slice(/\/\S+/).sub('.git','')[1..-1]
    	end

      def creation_time
      	::Naf::ApplicationType.first.created_at.strftime("%Y%m%d_%H%M%S")
      end

    end
  end
end
