# == Schema Information
#
# Table name: attendances
#
#  id          :bigint           not null, primary key
#  finished_at :datetime
#  started_at  :datetime
#  work_on     :date             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :bigint           not null
#
# Indexes
#
#  index_attendances_on_user_id              (user_id)
#  index_attendances_on_user_id_and_work_on  (user_id,work_on) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Attendance < ApplicationRecord
  # -------------------------------------------------------------------

  # !! 5:00 区切りの場合、複雑化したため0:00に修正 !!
  # 他の箇所はコメント含めそのままにしておく（テストのみ修正）
  CUTOFF_HOUR = 0

  # -------------------------------------------------------------------

  belongs_to :user
  has_many :breaktimes, dependent: :destroy

  # user_id に対して、workday が一意(unique)となることを強制
  validates :work_on, presence: true, uniqueness: { scope: :user_id }
  validate :_finished_after_started
  validate :_finished_requires_started

  # 出勤時に work_on を自動算出
  before_validation :_set_work_on, if: -> { started_at.present? && will_save_change_to_started_at? }

  # 出勤基準で業務日を決める（カットオフ補正）
  def self.business_date(time)
    (time.in_time_zone - CUTOFF_HOUR.hours).to_date
  end

  def self.clock_in!(user, now = Time.zone.now)
    Attendances::Punch.new(user: user, now: now, cutoff_hour: CUTOFF_HOUR).clock_in!
  end

  def self.clock_out!(user, now = Time.zone.now)
    Attendances::Punch.new(user: user, now: now, cutoff_hour: CUTOFF_HOUR).clock_out!
  end

  def worked_seconds
    return 0 unless started_at && finished_at

    (finished_at - started_at) - break_seconds
  end

  def break_seconds
    breaktimes.sum { |b| b.finished_at ? (b.finished_at - b.started_at) : 0 }
  end

  private

  def _set_work_on
    self.work_on = self.class.business_date(started_at)
  end

  def _finished_after_started
    return unless started_at.present? && finished_at.present?

    return unless finished_at < started_at

    errors.add(:finished_at, :after_started)
  end

  def _finished_requires_started
    return unless finished_at.present? && started_at.blank?

    errors.add(:started_at, :required_before_finished)
  end
end
