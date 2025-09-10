require 'rails_helper'

RSpec.describe "Attendances", type: :request do

  let(:user) { create(:user) }

  describe "GET /users/:user_id/attendance (show)" do
    it "ログイン必須" do
      get user_current_attendance_path(user)
      expect(response).to redirect_to(new_session_path)
    end

    it "ログイン後は 200" do
      sign_in(user)
      get user_current_attendance_path(user)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /users/:user_id/attendances (index)" do
    it "200 を返す" do
      sign_in(user)
      get user_attendances_path(user, month: Date.current.strftime("%Y-%m"))
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(<turbo-frame id="selected-month">))
      expect(response.body).to include(%(<table))
    end
  end

  describe "Turbo row editing" do
    before { sign_in(user) }

    it "edit: turbo-stream が返る" do
      a = create(:attendance, :finished, user: user, work_on: Date.new(2025,9,1))
      get edit_user_attendance_path(user, a, format: :turbo_stream)
      expect(response.media_type).to eq Mime[:turbo_stream]
      expect(response.body).to include(%(action="replace"))
      expect(response.body).to include(%(id="#{ActionView::RecordIdentifier.dom_id(a)}"))
    end

    it "save_row: 時刻を更新して turbo-stream で行を差し替え" do
      a = create(:attendance, user: user, work_on: Date.new(2025,9,1), started_at: Time.zone.parse("2025-09-01 09:00"))
      patch user_attendance_edit_session_path(user, a, format: :turbo_stream),
            params: { attendance: { started_at_hm: "10:00", finished_at_hm: "18:00" } }
      expect(response.media_type).to eq Mime[:turbo_stream]
      a.reload
      expect(a.started_at.strftime("%H:%M")).to eq "10:00"
      expect(a.finished_at.strftime("%H:%M")).to eq "18:00"
      expect(response.body).to include("10:00")
      expect(response.body).to include("18:00")
    end

    it "create: 未登録日でもフォーム表示できる" do
      date = Date.new(2025,9,2)
      post user_attendances_path(user, format: :turbo_stream), params: { date: date.to_s }
      expect(response.media_type).to eq Mime[:turbo_stream]
      expect(response.body).to include(%(target="attendance-#{date.strftime('%Y%m%d')}"))
      expect(response.body).to include(%(<tr id="attendance_))
    end

    it "cancel_edit: 空の新規レコードは削除され未登録表示へ戻す" do
      date = Date.new(2025,9,3)
      a = user.attendances.create!(work_on: date) # started/finished なし
      delete user_attendance_edit_session_path(user, a, format: :turbo_stream)
      expect(response.media_type).to eq Mime[:turbo_stream]
      expect(user.attendances.where(id: a.id)).to be_empty
      expect(response.body).to include("未登録").or include("—")
    end
  end

  describe "POST/PATCH 打刻" do
    before { sign_in(user) }

    it "POST /attendance 出勤が作成される" do
      expect {
        post user_current_attendance_path(user)
      }.to change { user.attendances.count }.by(1)
      expect(response).to redirect_to(root_path)
    end

    it "PATCH /attendance 退勤できる" do
      Attendance.clock_in!(user) # 先に出勤
      expect {
        patch user_current_attendance_path(user)
      }.to change { user.attendances.where("finished_at IS NOT NULL").count }.by(1)
      expect(response).to redirect_to(root_path)
    end
  end
  describe "GET /users/:user_id/attendances (index)" do
    it "200 を返す" do
      sign_in(user)
      get user_attendances_path(user, month: Date.current.beginning_of_month.to_s)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /users/:user_id/attendance (show)" do
    it "200 を返す" do
      sign_in(user)
      get user_current_attendance_path(user)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /users/:user_id/attendance (create)" do
    it "出勤できる" do
      sign_in(user)
      post user_current_attendance_path(user)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /users/:user_id/attendance (update)" do
    it "退勤できる" do
      sign_in(user)
      Attendance.clock_in!(user)
      patch user_current_attendance_path(user)
      expect(response).to redirect_to(root_path)
    end
  end
end
