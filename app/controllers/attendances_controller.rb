class AttendancesController < ApplicationController
  before_action :require_login

  def index
    @month = Date.current.beginning_of_month
    @attendances = current_user.attendances.in_month(@month)

    bizdate = Attendance.business_date(Time.zone.now)
    @today   = current_user.attendances.find_by(work_date: bizdate)
    @opened_break = @today&.breaktimes&.opened&.first
  end

  def create
    Attendance.clock_in!(current_user)
    redirect_to attendances_path, notice: "出勤しました"
  rescue => e
    redirect_to attendances_path, alert: e.message
  end

  def update
    Attendance.clock_out!(current_user)
    redirect_to attendances_path, notice: "退勤しました"
  rescue => e
    redirect_to attendances_path, alert: e.message
  end

  def edit
    @attendance = current_user.attendances.find(params[:id])
  end
end
