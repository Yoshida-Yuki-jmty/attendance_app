module FormatHelper
  def format_hm(t)
    t&.in_time_zone&.strftime("%H:%M")
  end

  # 時刻 → "HH:MM" or "-"
  def format_time_or_dash(time)
    time.present? ? format_hm(time) : "-"
  end

  # 秒数 → "HH:MM" or "-"
  def format_hhmm_or_dash(seconds)
    s = seconds.to_i
    s.positive? ? Time.at(s).utc.strftime("%H:%M") : "-"
  end

  def format_jp_md(date)
    date&.strftime("%-m月%-d日")
  end

  def format_jp_wday(date)
    %w(日 月 火 水 木 金 土)[date.wday]
  end
end
