module AttendanceStatusHelper
  # 指定した勤務日の状態判定をするメソッド（:none / :working / :on_break / :clocked_out）
  def common_status_key(attendance, opened_break = nil)
    return :none        if attendance.nil?
    return :clocked_out if attendance.finished_at.present?

    opened_break ||= attendance.respond_to?(:breaktimes) &&
                     attendance.breaktimes.exists?(finished_at: nil)

    return :on_break    if opened_break
    return :working     if attendance.started_at.present?
    :none
  end
end
