# app/controllers/concerns/saveable.rb
module Saveable
  extend ActiveSupport::Concern

  private

  def apply_attendance_update!(attendance)
    update_data    = params.require(:attendance).permit(:started_at, :finished_at).to_h
    started_at_hm  = params.dig(:attendance, :started_at_hm)
    finished_at_hm = params.dig(:attendance, :finished_at_hm)
    break_total_hm = params.dig(:attendance, :break_total_hm)

    update_data[:started_at]  = build_datetime(attendance.work_on, started_at_hm)  unless started_at_hm.nil?
    update_data[:finished_at] = build_datetime(attendance.work_on, finished_at_hm) unless finished_at_hm.nil?

    Attendance.transaction do
      attendance.update!(update_data)

      unless break_total_hm.nil?
        total_seconds = parse_hm_to_seconds(attendance, break_total_hm)
        if total_seconds < 0
          attendance.errors.add(:base, I18n.t("activerecord.errors.models.attendance.messages.break_total_negative"))
          raise ActiveRecord::RecordInvalid, attendance
        end

        attendance.breaktimes.destroy_all
        if total_seconds > 0
          base = (attendance.started_at || Time.zone.parse("#{attendance.work_on} 9:00")) + 5.hours
          attendance.breaktimes.create!(started_at: base, finished_at: base + total_seconds)
        end
      end
    end

    attendance
  end

  def unregistered?(attendance)
    attendance.started_at.blank? && attendance.finished_at.blank? && attendance.breaktimes.blank?
  end

  def build_datetime(date, hm)
    return nil if hm.blank?
    Time.zone.parse("#{date} #{hm}")
  end

  def parse_hm_to_seconds(attendance, hm)
    return 0 if hm.blank?
    unless hm =~ /\A\d{1,2}:\d{2}\z/
      raise ActiveRecord::RecordInvalid.new(attendance), I18n.t("activerecord.errors.models.attendance.messages.break_total_format")
    end
    h, m = hm.split(":").map!(&:to_i)
    h * 3600 + m * 60
  end
end
