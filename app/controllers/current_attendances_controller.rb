class CurrentAttendancesController < ApplicationController
  before_action :require_login

  rescue_from Attendance::AlreadyClockedOutError, with: :_handle_attendance_error
  rescue_from Attendance::NoClockInError,         with: :_handle_attendance_error
  rescue_from ActiveRecord::RecordInvalid,        with: :_handle_attendance_error

  def show
    @current_attendance = _current_attendance
    @opened_break       = _opened_break
  end

  def create   # 打刻: 出勤
    _punch!(:in,  notice: t("attendances.notices.clocked_in"))
  end

  def update   # 打刻: 退勤
    _punch!(:out, notice: t("attendances.notices.clocked_out"))
  end

  private

  # ＝＝＝ 表示用の取得（メモ化） ＝＝＝
  def _current_attendance
    @current_attendance ||= current_user
      .attendances
      .includes(:breaktimes)
      .find_or_initialize_by(work_date: business_today)
  end

  def _opened_break
    opened_break ||= _current_attendance.breaktimes.opened.first
  end

  # ＝＝＝ 出退勤の共通処理 ＝＝＝
  def _punch!(direction, notice:)
    case direction
    when :in  then Attendance.clock_in!(current_user)
    when :out then Attendance.clock_out!(current_user)
    else           raise ArgumentError, "unknown punch direction: #{direction}"
    end
    redirect_to root_path, notice: notice
  end

  # ＝＝＝ 例外一本化 ＝＝＝
  def _handle_attendance_error(e)
    redirect_to root_path, alert: e.message
  end
end
