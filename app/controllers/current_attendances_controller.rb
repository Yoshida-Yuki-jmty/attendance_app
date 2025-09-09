class CurrentAttendancesController < ApplicationController
  before_action :require_login

  def show
    bizdate       = Attendance.business_date(Time.zone.now)
    @today        = current_user.attendances.includes(:breaktimes).find_or_initialize_by(work_date: bizdate)
    @opened_break = @today&.breaktimes&.opened&.first
  end

  def create
    Attendance.clock_in!(current_user)
    redirect_to root_path, notice: t("attendances.notices.clocked_in")
  rescue Attendance::AlreadyClockedOutError => e
    redirect_to root_path, alert: e.message
  rescue ActiveRecord::RecordInvalid => e
    redirect_to root_path, alert: e.record.errors.full_messages.to_sentence
  end

  def update
    Attendance.clock_out!(current_user)
    redirect_to root_path, notice: t("attendances.notices.clocked_out")
  rescue Attendance::NoClockInError => e
    redirect_to root_path, alert: e.message
  rescue ActiveRecord::RecordInvalid => e
    redirect_to root_path, alert: e.record.errors.full_messages.to_sentence
  end
end
