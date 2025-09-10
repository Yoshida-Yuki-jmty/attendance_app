# app/services/attendances/punch.rb
module Attendances
  class Punch
    def initialize(user:, now: Time.zone.now, cutoff_hour: Attendance::CUTOFF_HOUR)
      @user        = user
      @now         = now
      @cutoff_hour = cutoff_hour
    end

    def clock_in!
      business_today = _business_date(@now)
      attendance = @user.attendances.find_by(work_on: business_today)

      if attendance
        if attendance.finished_at.present?
          raise Attendances::AlreadyClockedOutError, I18n.t("attendances.errors.already_clocked_out")
        else
          attendance.update!(started_at: @now)
        end
      else
        @user.attendances.create!(work_on: business_today, started_at: @now)
      end
    end

    def clock_out!
      business_today = _business_date(@now)
      attendance     =  @user.attendances.find_by(work_on: business_today) ||
                        @user.attendances.find_by(work_on: business_today - 1)

      raise Attendances::NoClockInError, I18n.t("attendances.errors.no_clock_in") unless attendance

      cutoff_end = _cutoff_end_for(attendance.work_on)

      if @now < cutoff_end
        if (br = attendance.breaktimes.opened.first)
          br.update!(finished_at: @now)
        end
        attendance.update!(finished_at: @now)
        return attendance
      end

      ActiveRecord::Base.transaction do
        if (br = attendance.breaktimes.opened.first)
          br.update!(finished_at: cutoff_end)
        end
        if attendance.finished_at.blank? || attendance.finished_at < cutoff_end
          attendance.update!(finished_at: cutoff_end)
        end

        next_date = attendance.work_on + 1
        next_attendance = @user.attendances.find_or_initialize_by(work_on: next_date)
        next_attendance.started_at ||= cutoff_end
        next_attendance.update!(finished_at: @now)
        next_attendance
      end
    end

    private

    def _business_date(time)
      (time.in_time_zone - @cutoff_hour.hours).to_date
    end

    def _cutoff_end_for(work_on)
      Time.zone.local(work_on.year, work_on.month, work_on.day, @cutoff_hour) + 1.day
    end
  end
end
