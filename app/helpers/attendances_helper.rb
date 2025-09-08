module AttendancesHelper
  def hm(t)
    t&.in_time_zone&.strftime("%H:%M")
  end

  # @today: 今日の勤怠レコード（なければ nil）
  # @opened_break: 進行中の休憩（なければ nil）
  def attendance_status_key(today, opened_break)
    return :none        if today.nil?
    return :clocked_out if today.finished_at.present?
    return :on_break    if opened_break.present?
    return :working     if today.started_at.present?
    :none
  end

  def attendance_status_label(key)
    {
      none:        "日報未登録",
      working:     "出勤中",
      on_break:    "休憩中",
      clocked_out: "退勤済"
    }[key]
  end

  # バッジごと出したい場合（Tailwind想定）
  def attendance_status_badge(today, opened_break)
    key   = attendance_status_key(today, opened_break)
    label = attendance_status_label(key)
    color = {
      none:        "bg-gray-200 text-gray-700",
      working:     "bg-emerald-100 text-emerald-700",
      on_break:    "bg-amber-100 text-amber-700",
      clocked_out: "bg-sky-100 text-sky-700"
    }[key]

    content_tag(:span, label, class: "inline-flex items-center px-2 py-0.5 rounded text-sm font-medium #{color}")
  end

  def attendance_button_disabled?(action, today, opened_break)
    matrix = {
      none:        { clock_in: false, clock_out: true,  break_start: true,  break_end: true  },
      working:     { clock_in: true,  clock_out: false, break_start: false, break_end: true  },
      on_break:    { clock_in: true,  clock_out: false, break_start: true,  break_end: false }, # 休憩中でも退勤を許可
      clocked_out: { clock_in: true,  clock_out: false,  break_start: true,  break_end: true  }
    }
    key = attendance_status_key(today, opened_break)
    matrix[key][action]
  end

  # 見た目クラス（disabled のとき半透明＋not-allowed）
  def button_ui_class(disabled)
    "px-3 py-1 border rounded #{'opacity-50 cursor-not-allowed' if disabled}"
  end
end
