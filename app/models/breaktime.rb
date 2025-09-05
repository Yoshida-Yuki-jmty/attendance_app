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
#  index_breaktimes_on_attendance_id  (attendance_id)
#
# Foreign Keys
#
#  fk_rails_...  (attendance_id => attendances.id)
#
class Breaktime < ApplicationRecord
  belongs_to :attendance
  validate :finished_after_started

  scope :opened, -> { where(finished_at: nil) }

  def self.start_break_for!(attendance, now = Time.zone.now)
    raise StandardError, "退勤済みです" if attendance.finished_at.present?
    raise StandardError, "すでに休憩中です" if attendance.breaktimes.opened.exists?
    attendance.breaktimes.create!(started_at: now)
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
end
