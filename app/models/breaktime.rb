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

  validates :started_at, presence: true
  validate :_finished_after_started
  validate :_only_one_open_break, if: -> { finished_at.nil? }

  scope :opened, -> { where(finished_at: nil).order(:started_at) }

  def self.start_break_for!(attendance, now = Time.zone.now)
    raise StandardError, I18n.t('breaktimes.errors.cannot_start_after_clock_out') if attendance.finished_at.present?

    attendance.with_lock do
      raise StandardError, I18n.t('breaktimes.errors.already_on_break') if attendance.breaktimes.opened.exists?

      attendance.breaktimes.create!(started_at: now)
    end
  end

  private

  def _finished_after_started
    return unless started_at && finished_at

    errors.add(:finished_at, :after_started) if finished_at < started_at
  end

  def _only_one_open_break
    return unless attendance.breaktimes.where(finished_at: nil).where.not(id: id).exists?

    errors.add(:base, I18n.t('activerecord.errors.models.breaktime.messages.only_one_open_break'))
  end
end
