class BreaktimesController < ApplicationController
  before_action :require_login

  # 休憩開始
  def create
    attendance = current_attendance
    if attendance.nil?
      redirect_to attendances_path, alert: "出勤後に休憩を開始できます"
      return
    end

    Breaktime.start_break_for!(attendance)
    redirect_to attendances_path, notice: "休憩を開始しました"
  rescue => e
    redirect_to attendances_path, alert: e.message
  end

  # 休憩終了
  def update
    breaktime = current_user.breaktimes.find(params[:id])
    if breaktime.finished_at.present?
      return redirect_to attendances_path, alert: "この休憩は既に終了しています"
    end

    breaktime.update!(finished_at: Time.zone.now)
    redirect_to attendances_path, notice: "休憩を終了しました"
  rescue ActiveRecord::RecordNotFound
    redirect_to attendances_path, alert: "休憩が見つかりません"
  rescue => e
    redirect_to attendances_path, alert: e.message
  end

  private

  # 今日の論理日の出勤を探す
  def current_attendance
    bizdate = Attendance.business_date(Time.zone.now)
    current_user.attendances.find_by(work_date: bizdate)
  end
end
