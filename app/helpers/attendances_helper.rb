module AttendancesHelper
  def hm(t)
    t&.in_time_zone&.strftime("%H:%M")
  end
end
