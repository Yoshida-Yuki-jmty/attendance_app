module BusinessDateable
  extend ActiveSupport::Concern

  included do
    helper_method :business_today
  end

  # CUTOFF を考慮した「今日の業務日」（Date）
  def business_today
    @business_today ||= Attendance.business_date(Time.zone.now)
  end
end
