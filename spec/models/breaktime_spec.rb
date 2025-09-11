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
require 'rails_helper'

RSpec.describe Breaktime, type: :model do
  describe 'validations' do
    it '終了は開始以降' do
      bt = build(:breaktime, started_at: Time.zone.parse('12:00'), finished_at: Time.zone.parse('11:59'))
      expect(bt).to be_invalid
      expect(bt.errors[:finished_at]).to include('は休憩開始以降にしてください')
    end

    it '同じ勤怠に開いている休憩は1件だけ' do
      a = create(:attendance, :finished, finished_at: nil) # 明示的に未退勤でもOK
      create(:breaktime, attendance: a, finished_at: nil)  # 開いたまま
      dup = build(:breaktime, attendance: a, finished_at: nil)
      expect(dup).to be_invalid
      expect(dup.errors[:base]).to include('すでに休憩中です')
    end
  end

  describe '.start_break_for!' do
    it '未退勤・未休憩なら作成' do
      a = create(:attendance, finished_at: nil)
      expect do
        Breaktime.start_break_for!(a)
      end.to change { a.breaktimes.count }.by(1)
    end

    it '退勤済はエラー' do
      a = create(:attendance, :finished)
      expect { Breaktime.start_break_for!(a) }.to raise_error(StandardError, /退勤済み/)
    end

    it '開いている休憩があればエラー' do
      a = create(:attendance, finished_at: nil)
      create(:breaktime, attendance: a, finished_at: nil)
      expect { Breaktime.start_break_for!(a) }.to raise_error(StandardError, /すでに休憩中/)
    end
  end
end
