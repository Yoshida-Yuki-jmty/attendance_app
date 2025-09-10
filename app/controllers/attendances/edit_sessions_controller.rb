module Attendances
  class EditSessionsController < ApplicationController
    include ActionView::RecordIdentifier
    before_action :require_login

    def destroy
      attendance = current_user.attendances.find(params[:attendance_id])
      selected   = attendance.work_on
      target_id  = dom_id(attendance)

      if attendance.started_at.blank? && attendance.finished_at.blank? && attendance.breaktimes.blank?
        attendance.destroy
        render turbo_stream: turbo_stream.replace(
          target_id,
          partial: "attendances/row_display",
          locals: { attendance: nil, date: selected, today: business_today }
        )
      else
        render turbo_stream: turbo_stream.replace(
          target_id,
          partial: "attendances/row_display",
          locals: { attendance: attendance, date: selected, today: business_today }
        )
      end
    end
  end
end
