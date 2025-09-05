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
  CUTOFF_HOUR = 5 # 5:00 区切り

  belongs_to :user
  has_many :breaktimes, dependent: :destroy

  validates :work_date, presence: true, uniqueness: { scope: :user_id }
  validate :finished_after_started

  # 出勤時に work_date を自動算出
  before_validation :set_work_date, if: -> { started_at.present? && will_save_change_to_started_at? }

  scope :of_user, ->(user) { where(user_id: user.id) }
  scope :in_month, ->(d) { where(work_date: d.beginning_of_month..d.end_of_month).order(work_date: :desc) }

  # 出勤基準で業務日を決める（5:00カットオフ補正）
  def self.business_date(time)
    (time.in_time_zone - CUTOFF_HOUR.hours).to_date
  end

  # 出勤打刻
  def self.clock_in!(user, now = Time.zone.now)
    biz = business_date(now)
    att = user.attendances.find_by(work_date: biz)

    if att
      raise StandardError, "本日は退勤済みです" if att.finished_at.present?
      att.update!(started_at: now) # 2回目以降は出勤時刻を更新
      att
    else
      user.attendances.create!(work_date: biz, started_at: now)
    end
  end

  # 退勤打刻（5:00跨ぎなら翌日分を自動追加）
  def self.clock_out!(user, now = Time.zone.now)
    biz = business_date(now)
    att = user.attendances.find_by(work_date: biz)
    raise StandardError, "本日の出勤打刻がありません" if att.nil?
    raise StandardError, "すでに退勤済みです"         if att.finished_at.present?
    
    cutoff_end = Time.zone.local(
      att.work_date.year,
      att.work_date.month,
      att.work_date.day,
      CUTOFF_HOUR
    ) + 1.day

    if now < cutoff_end
      att.update!(finished_at: now)
      return att
    end

    # 5:00 を跨ぐ場合 → 分割保存
    Attendance.transaction do
      att.update!(finished_at: cutoff_end)

      next_date = att.work_date + 1
      next_att  = user.attendances.find_or_initialize_by(work_date: next_date)
      next_att.started_at ||= cutoff_end
      next_att.update!(finished_at: now)
      next_att
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

  def set_work_date
    self.work_date = self.class.business_date(started_at)
  end

  def finished_after_started
    return unless started_at && finished_at
    errors.add(:finished_at, "は出勤以降にしてください") if finished_at < started_at
  end
end
