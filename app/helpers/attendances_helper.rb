module AttendancesHelper

  def daily_status_key(attendance, date)
    base = common_status_key(attendance)
    return :future_blank if base == :none && date.to_date > business_today
    return :blank        if base == :none
    base # :working / :on_break / :clocked_out
  end

  def daily_status_label(key)
    {
      blank:        "未登録",
      future_blank: "-",
      working:      "出勤中",
      on_break:     "休憩中",
      clocked_out:  "退勤済み"
    }[key]
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
