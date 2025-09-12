class CurrentAttendancesController < ApplicationController
  before_action :require_login

  rescue_from Attendances::AlreadyClockedOutError, with: :_handle_attendance_error
  rescue_from Attendances::NoClockInError,         with: :_handle_attendance_error
  rescue_from ActiveRecord::RecordInvalid,         with: :_handle_attendance_error

  def show
    @current_attendance = _current_attendance
    @opened_break       = _opened_break
  end

  def create   # 出勤
    Attendance.punch!(user: current_user, direction: :in)
    redirect_to root_path, notice: t('attendances.notices.clocked_in')
  end

  def update   # 退勤
    Attendance.punch!(user: current_user, direction: :out)
    redirect_to root_path, notice: t('attendances.notices.clocked_out')
  end

  private

  # ＝＝＝ 表示用の取得（メモ化） ＝＝＝
  def _current_attendance
    @current_attendance ||= current_user
                            .attendances
                            .includes(:breaktimes)
                            .find_or_initialize_by(work_on: business_today)
  end

  def _opened_break
    opened_break ||= _current_attendance.breaktimes.opened.first
  end

  def _handle_attendance_error(e)
    redirect_to root_path, alert: e.message
  end
end
