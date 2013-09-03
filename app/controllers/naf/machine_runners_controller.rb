module Naf
  class MachineRunnersController < Naf::ApplicationController

    before_filter :set_rows_per_page

    def index
      respond_to do |format|
        format.html
        format.json do
          set_page

          @total_records = ::Naf::MachineRunner.count(:all)
          @rows = ::Logical::Naf::MachineRunner.to_array(params['iSortCol_0'].to_i, params['sSortDir_0']).
            paginate(page: @page, per_page: @rows_per_page)

          render layout: 'naf/layouts/jquery_datatables'
        end
      end
    end

    def show
      @machine_runner = Naf::MachineRunner.find(params[:id])
    end

  end
end
