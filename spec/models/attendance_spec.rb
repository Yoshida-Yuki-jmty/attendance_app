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
require 'rails_helper'

RSpec.describe Attendance, type: :model do
  describe "validations" do
    it "同一ユーザーで work_on の重複を許可しない" do
      u = create(:user)
      create(:attendance, user: u, work_on: Date.new(2025,9,1))
      dup = build(:attendance, user: u, work_on: Date.new(2025,9,1))
      expect(dup).to be_invalid
      expect(dup.errors[:work_on]).to be_present
    end

    it "finished_at は started_at 以降でないと無効" do
      a = build(:attendance,
        started_at:  Time.zone.parse("2025-09-01 10:00"),
        finished_at: Time.zone.parse("2025-09-01 09:59"))
      expect(a).to be_invalid
      expect(a.errors[:finished_at]).to include("は出勤以降にしてください")
    end
  end

  describe ".business_date" do
    it "00:00 ちょうどは当日扱い" do
      travel_to Time.zone.parse("2025-09-08 00:00") do
        expect(Attendance.business_date(Time.zone.now)).to eq Date.new(2025,9,8)
      end
    end

    it "23:59 も当日扱い" do
      travel_to Time.zone.parse("2025-09-08 23:59") do
        expect(Attendance.business_date(Time.zone.now)).to eq Date.new(2025,9,8)
      end
    end
  end

  describe ".clock_in!" do
    let(:user) { create(:user) }

    it "レコードが無ければ作成する" do
      travel_to Time.zone.parse("2025-09-08 09:00") do
        expect {
          Attendance.clock_in!(user)
        }.to change { user.attendances.count }.by(1)
        a = user.attendances.last
        expect(a.work_on).to eq Date.new(2025,9,8)
        expect(a.started_at).to be_present
        expect(a.finished_at).to be_nil
      end
    end

    it "退勤済ならエラー" do
      # ← その日の勤怠（退勤済）が存在する時刻に固定して検証する
      travel_to Time.zone.parse("2025-09-08 10:00") do
        create(:attendance, :finished, user: user, work_on: Date.new(2025,9,8))
        expect {
          Attendance.clock_in!(user)
        }.to raise_error(Attendances::AlreadyClockedOutError)
      end
    end
  end

  describe ".clock_out!" do
    let(:user) { create(:user) }

    it "出勤が無ければエラー" do
      expect { Attendance.clock_out!(user) }
        .to raise_error(Attendances::NoClockInError)
    end

    it "CUTOFF時刻 以内なら同日で finished_at 更新" do
      travel_to Time.zone.parse("2025-09-08 09:00") do
        Attendance.clock_in!(user)
      end
      travel_to Time.zone.parse("2025-09-08 18:00") do
        expect {
          Attendance.clock_out!(user)
        }.to change { user.attendances.count }.by(0)
        a = user.attendances.last
        expect(a.finished_at).to be_present
      end
    end

    it "0:00 を跨ぐなら分割保存される" do
      # 23:00 出勤
      travel_to Time.zone.parse("2025-09-08 23:00") do
        Attendance.clock_in!(user)
      end
      # 翌 06:00 退勤
      travel_to Time.zone.parse("2025-09-09 06:00") do
        Attendance.clock_out!(user)
      end

      a1 = user.attendances.find_by(work_on: Date.new(2025,9,8))
      a2 = user.attendances.find_by(work_on: Date.new(2025,9,9))

      expect(a1.finished_at.strftime("%H:%M")).to eq "00:00"
      expect(a2.started_at.strftime("%H:%M")).to  eq "00:00"
      expect(a2.finished_at.strftime("%H:%M")).to eq "06:00"
    end
  end

  describe "#break_seconds / #worked_seconds" do
    it "休憩を差し引いた実働を返す" do
      a  = create(:attendance, started_at: Time.zone.parse("2025-09-08 09:00"))
      a.update!(finished_at: Time.zone.parse("2025-09-08 18:00"))
      create(:breaktime, attendance: a, started_at: Time.zone.parse("2025-09-08 12:00"), finished_at: Time.zone.parse("2025-09-08 12:30"))
      expect(a.break_seconds).to eq 30.minutes
      expect(a.worked_seconds).to  eq 8.5.hours
    end
  end
end
