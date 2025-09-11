module CurrentAttendancesHelper
  def daily_status_badge(today, opened_break)
    key   = common_status_key(today, opened_break)
    label = {
      none: '日報未登録',
      working: '出勤中',
      on_break: '休憩中',
      clocked_out: '退勤済'
    }[key]
    color = {
      none: 'bg-gray-200 text-gray-700',
      working: 'bg-emerald-100 text-emerald-700',
      on_break: 'bg-amber-100 text-amber-700',
      clocked_out: 'bg-sky-100 text-sky-700'
    }[key]

    content_tag(:span, label,
                class: "inline-flex items-center px-2 py-0.5 rounded text-sm font-medium #{color}")
  end

  # 日報の状況のマッピングテーブル
  def attendance_button_disabled?(action, today, opened_break)
    matrix = {
      none: { clock_in: false, clock_out: true, break_start: true, break_end: true },
      working: { clock_in: true, clock_out: false, break_start: false, break_end: true },
      on_break: { clock_in: true, clock_out: false, break_start: true, break_end: false },
      clocked_out: { clock_in: true, clock_out: false, break_start: true, break_end: true }
    }
    key = common_status_key(today, opened_break)
    matrix[key][action]
  end

  # 見た目クラス（disabled のとき半透明＋not-allowed）
  def button_ui_class(disabled)
    "px-3 py-1 border rounded #{'opacity-50 cursor-not-allowed' if disabled}"
  end

  # 「休憩（開始-終了）」の複数行 HTML（なければ "-")
  def breaktimes_html(attendance)
    return '-' unless attendance&.breaktimes&.any?

    items = attendance.breaktimes.order(:started_at).map do |bt|
      content_tag(:div, [format_hm(bt.started_at), format_hm(bt.finished_at)].compact.join(' - '))
    end
    safe_join(items)
  end
end
