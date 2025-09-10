class BreaktimesController < ApplicationController
  before_action :require_login

  # 休憩開始
  def create
    attendance = _current_attendance
    if attendance.nil?
      redirect_to user_current_attendance_path(current_user), alert: I18n.t("breaktimes.errors.must_clock_in_first")
      return
    end

    Breaktime.start_break_for!(attendance)
    redirect_to user_current_attendance_path(current_user), notice: I18n.t("breaktimes.notices.started")
  rescue ActiveRecord::RecordNotUnique
    redirect_to user_current_attendance_path(current_user), alert: I18n.t("breaktimes.errors.already_on_break")
  rescue => e
    redirect_to user_current_attendance_path(current_user), alert: e.message
  end

  # 休憩終了
  def update
    breaktime = current_user.breaktimes.find(params[:id])
    if breaktime.finished_at.present?
      return redirect_to user_current_attendance_path(current_user), alert: I18n.t("breaktimes.errors.already_finished")
    end

    breaktime.update!(finished_at: Time.zone.now)
    redirect_to user_current_attendance_path(current_user), notice: I18n.t("breaktimes.notices.finished")
  rescue ActiveRecord::RecordNotFound
    redirect_to user_current_attendance_path(current_user), alert: I18n.t("breaktimes.errors.not_found")
  rescue => e
    redirect_to user_current_attendance_path(current_user), alert: e.message
  end

  private

  # 今日の論理日の出勤を探す
  def _current_attendance
    current_user.attendances.find_by(work_date: business_today)
  end
end
