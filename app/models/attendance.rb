# == Schema Information
#
# Table name: attendances
#
#  id          :bigint           not null, primary key
#  finished_at :datetime
#  started_at  :datetime
#  work_date   :date
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :bigint           not null
#
# Indexes
#
#  index_attendances_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Attendance < ApplicationRecord

  class NoClockInError         < StandardError; end
  class AlreadyClockedOutError < StandardError; end

  # -------------------------------------------------------------------

  # !! 5:00 区切りの場合、複雑化したため0:00に修正 !!
  # 他の箇所はコメント含めそのままにしておく（テストのみ修正）
  CUTOFF_HOUR = 0 

  # -------------------------------------------------------------------

  belongs_to :user
  has_many :breaktimes, dependent: :destroy

  # user_id に対して、workday が一意(unique)となることを強制
  validates :work_date, presence: true, uniqueness: { scope: :user_id }
  validate :_finished_after_started
  validate :_finished_requires_started

  # 出勤時に work_date を自動算出
  before_validation :_set_work_date, if: -> { started_at.present? && will_save_change_to_started_at? }

  # 出勤基準で業務日を決める（カットオフ補正）
  def self.business_date(time)
    (time.in_time_zone - CUTOFF_HOUR.hours).to_date
  end

  # 出勤打刻
  def self.clock_in!(user, now = Time.zone.now)
    business_today = business_date(now)
    attendance = user.attendances.find_by(work_date: business_today)

    if attendance && 
      if attendance.finished_at.present?
        raise AlreadyClockedOutError, I18n.t("attendances.errors.already_clocked_out")
      else
        attendance.update!(started_at: now)
      end
    else
      user.attendances.create!(work_date: business_today, started_at: now)
    end
  end

  # 退勤打刻（CUTOFF時刻 跨ぎなら翌日分を自動追加）
  def self.clock_out!(user, now = Time.zone.now)
    business_today = business_date(now)
    attendance = user.attendances.find_by(work_date: business_today)||
          user.attendances.find_by(work_date: business_today - 1)

    raise NoClockInError, I18n.t("attendances.errors.no_clock_in") if attendance.nil?

    cutoff_end = Time.zone.local(
      attendance.work_date.year,
      attendance.work_date.month,
      attendance.work_date.day,
      CUTOFF_HOUR
    ) + 1.day

    if now < cutoff_end
      if (breaktime = attendance.breaktimes.opened.first)
        breaktime.update!(finished_at: now)
      end
      attendance.update!(finished_at: now)
      return attendance
    end

    # CUTOFF時刻 を跨ぐ場合 → 分割保存
    Attendance.transaction do
      if (breaktime = attendance.breaktimes.opened.first)
        breaktime.update!(finished_at: cutoff_end)
      end
      if attendance.finished_at.blank? || attendance.finished_at < cutoff_end
        attendance.update!(finished_at: cutoff_end)
      end

      next_date = attendance.work_date + 1
      next_attendance  = user.attendances.find_or_initialize_by(work_date: next_date)
      next_attendance.started_at ||= cutoff_end
      next_attendance.update!(finished_at: now)
      next_attendance
    end
  end

  def worked_seconds
    return 0 unless started_at && finished_at
    (finished_at - started_at) - break_seconds
  end

  def break_seconds
    breaktimes.sum { |b| b.finished_at ? (b.finished_at - b.started_at) : 0 }
  end

  private

  def _set_work_date
    self.work_date = self.class.business_date(started_at)
  end

  def _finished_after_started
    return unless started_at && finished_at
    errors.add(:finished_at, "は出勤以降にしてください") if finished_at < started_at
  end

  def _finished_requires_started
    if finished_at.present? && started_at.blank?
      errors.add(:started_at, "を先に入力してください")
    end
  end
end
