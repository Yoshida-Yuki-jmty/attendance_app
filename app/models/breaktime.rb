# == Schema Information
#
# Table name: breaktimes
#
#  id            :bigint           not null, primary key
#  finished_at   :datetime
#  started_at    :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  attendance_id :bigint           not null
#
# Indexes
#
#  index_breaktimes_on_attendance_id       (attendance_id)
#  index_breaktimes_on_attendance_id_open  (attendance_id) UNIQUE WHERE (finished_at IS NULL)
#
# Foreign Keys
#
#  fk_rails_...  (attendance_id => attendances.id)
#
class Breaktime < ApplicationRecord
  belongs_to :attendance
  validate :finished_after_started
  validate :only_one_open_break, if: -> { finished_at.nil? }

  scope :opened, -> { where(finished_at: nil).order(:started_at) }

  def self.start_break_for!(attendance, now = Time.zone.now)
    raise StandardError, "退勤済みです" if attendance.finished_at.present?
    attendance.with_lock do
      raise StandardError, "すでに休憩中です" if attendance.breaktimes.opened.exists?
      attendance.breaktimes.create!(started_at: now)
    end
  end

  # def self.finish_break_for!(attendance, now = Time.zone.now)
  #   bt = attendance.breaktimes.opened.first
  #   raise StandardError, "休憩が開始されていません" if bt.nil?
  #   bt.update!(finished_at: now)
  # end

  private

  def finished_after_started
    return unless started_at && finished_at
    errors.add(:finished_at, "は休憩開始以降にしてください") if finished_at < started_at
  end

  def only_one_open_break
    if attendance.breaktimes.where(finished_at: nil).where.not(id: id).exists?
      errors.add(:base, "すでに休憩中です")
    end
  end
end
