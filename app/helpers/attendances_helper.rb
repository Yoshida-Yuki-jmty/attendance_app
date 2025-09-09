module AttendancesHelper
  def hm(t)
    t&.in_time_zone&.strftime("%H:%M")
  end

  # 時刻 → "HH:MM" or "-"
  def time_or_dash(time)
    time.present? ? hm(time) : "-"
  end

  # 秒数 → "HH:MM" or "-"
  def hhmm_or_dash(seconds)
    s = seconds.to_i
    s.positive? ? Time.at(s).utc.strftime("%H:%M") : "-"
  end

  # 指定した勤務日の状態判定をするメソッド
  def attendance_status_key(attendance, opened_break = nil)
    return :none        if attendance.nil?
    return :clocked_out if attendance.finished_at.present?

    opened_break ||= attendance.respond_to?(:breaktimes) &&
                    attendance.breaktimes.exists?(finished_at: nil)

    return :on_break    if opened_break
    return :working     if attendance.started_at.present?
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

  # 「休憩（開始-終了）」の複数行 HTML（なければ "-")
  def breaktimes_html(attendance)
    return "-" unless attendance&.breaktimes&.any?
    items = attendance.breaktimes.order(:started_at).map do |bt|
      content_tag(:div, [hm(bt.started_at), hm(bt.finished_at)].compact.join(" - "))
    end
    safe_join(items)
  end

  def row_status_key(a, d, today_date)
    base = attendance_status_key(a) # ← ここで共通判定を再利用
    return :future_blank if base == :none && d.to_date > today_date
    return :blank        if base == :none
    base # :working / :on_break / :clocked_out
  end

  def row_status_label(key)
    {
      blank:        "未登録",
      future_blank: "—",
      working:      "出勤中",
      on_break:     "休憩中",
      clocked_out:  "退勤済み"
    }[key]
  end

  def jp_md(date)
    date&.strftime("%-m月%-d日")
  end

  def jp_wday(date)
    %w(日 月 火 水 木 金 土)[date.wday]
  end

  # 祝日 or 日曜なら赤、土曜は青
  def holiday?(date)
    sunday = date.wday == 0
    pub_holiday = defined?(HolidayJp) && HolidayJp.holiday?(date)
    sunday || pub_holiday
  end

  def day_color_class(date)
    return "text-red-600"  if holiday?(date)
    return "text-blue-600" if date.wday == 6
    "text-gray-700"
  end
end
