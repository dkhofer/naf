module Naf
  class LogParsersController < Naf::ApiSimpleClusterAuthenticatorApplicationController

    def logs
      if !::Naf.configuration.expire_cookie || naf_cookie_valid?
        if params['record_id'].present?
          response = params['logical_type'].constantize.new(params).logs

          if response.present?
            status = :ok
          else
            status = :unprocessable_entity
          end
        else
          response = {
            logs: '&nbsp;&nbsp;<span>Record id is not present</br></span>'
          }
          status = :unprocessable_entity
        end

        render json: { status: status, data: response }
      else
        render json: { status: :unprocessable_entity }
      end
    end

    def download
      job_log_downloader = Logical::Naf::LogParser::JobDownloader.new({ 
        'record_id' => params[:record_id]
      })
      logs = job_log_downloader.logs_for_download + "\n"

      send_data(
        logs,
        filename: "job_#{params[:record_id]}_log.txt",
        type: "text/plain", disposition: 'attachment'
      )
    end

  end
end
