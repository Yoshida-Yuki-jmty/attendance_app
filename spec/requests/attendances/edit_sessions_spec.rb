require "rails_helper"

RSpec.describe "Attendances::EditSessionsController", type: :request do
  let(:user) { create(:user) }

  describe "POST /users/:user_id/attendances.turbo_stream" do
    let(:date)   { Date.new(2025,9,2) }
    let(:method) { :post }
    let(:path)   { user_attendances_path(user, format: :turbo_stream) }
    let(:params) {{ date: date.to_s }}

    context "ログイン済の場合" do
      before { sign_in(user) }
      it "勤怠未登録のレコードでもフォーム行を返す" do
        is_expected.to eq 200
        expect(response.media_type).to eq Mime[:turbo_stream]
        expect(response.body).to include(%(target="attendance-#{date.strftime('%Y%m%d')}"))
        expect(response.body).to include(%(<tr id="attendance_))
      end

      it "既存の勤怠レコードがあっても新規作成せずフォーム行を返す" do
        create(:attendance, user: user, work_on: date)
        expect {
          is_expected.to eq 200
        }.not_to change { user.attendances.where(work_on: date).count }
        expect(response.media_type).to eq Mime[:turbo_stream]
        expect(response.body).to include(%(target="attendance-#{date.strftime('%Y%m%d')}"))
        expect(response.body).to include(%(<tr id="attendance_))
      end
    end
  end

  describe "PATCH /users/:user_id/attendances/:id/edit_session.turbo_stream" do
    let!(:attendance) { create(:attendance, user: user, work_on: Date.new(2025,9,1), started_at: Time.zone.parse("2025-09-01 09:00")) }
    let(:method) { :patch }
    let(:path)   { user_attendance_edit_session_path(user, attendance, format: :turbo_stream) }
    let(:params) {{ attendance: { started_at_hm: "10:00", finished_at_hm: "18:00" } }}

    context "未ログインの場合" do
      it '更新されず、ログイン画面へリダイレクト' do
        expect {
          is_expected.to eq 302
          expect(response).to redirect_to(new_session_path)
        }.not_to change { attendance.reload.attributes.slice("started_at", "finished_at") }
      end
    end
    
    context "ログイン済の場合" do
      before { sign_in(user) }
      it do
        is_expected.to eq 200
        expect(response.media_type).to eq Mime[:turbo_stream]
        attendance.reload
        expect(attendance.started_at.strftime("%H:%M")).to eq "10:00"
        expect(attendance.finished_at.strftime("%H:%M")).to eq "18:00"
        expect(response.body).to include("10:00")
        expect(response.body).to include("18:00")
      end
    end
  end

  describe "DELETE /users/:user_id/attendances/:id/edit_session.turbo_stream" do
    let!(:attendance) { user.attendances.create!(work_on: Date.new(2025,9,3)) }
    let(:method) { :delete }
    let(:path)   { user_attendance_edit_session_path(user, attendance, format: :turbo_stream) }

    context "未ログインの場合" do
      it do
        is_expected.to eq 302
        expect(response).to redirect_to(new_session_path)
        # レコードは削除されない
        expect(user.attendances.exists?(attendance.id)).to be true
      end
    end

    context 'ログイン済の場合' do
      before { sign_in(user) }
      it do
        is_expected.to eq 200
        expect(user.attendances.where(id: attendance.id)).to be_empty
        expect(response.body).to include("未登録").or include("—")
      end
    end
  end
end
