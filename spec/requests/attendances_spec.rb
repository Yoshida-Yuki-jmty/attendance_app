require 'rails_helper'

RSpec.describe "Attendances", type: :request do

  let(:user) { create(:user) }

  describe "GET /users/:user_id/attendance" do
    let(:method) { :get }
    let(:path)   { user_current_attendance_path(user) }
    context "未ログインの場合" do
      it { is_expected.to eq 302 }
    end

    context "ログイン済の場合" do
      before { sign_in(user) }
      it do
        is_expected.to eq 200
        expect(response.body).to include("本日の日報")
      end
    end
  end

  context "GET /users/:user_id/attendances" do
    let(:method) { :get }
    let(:path)   { user_attendances_path(user, month: Date.current.strftime("%Y-%m")) }
    context "未ログインの場合" do
      it { is_expected.to eq 302 }
    end

    context "ログイン済の場合" do
      before { sign_in(user) }
      it do
        is_expected.to eq 200
        expect(response.body).to include(%(<turbo-frame id="selected-month">))
        expect(response.body).to include("<table")
      end
    end
  end

  context "ログイン前提のアクション" do
    before { sign_in(user) }

    context "GET /users/:user_id/attendances/:id/edit.turbo_stream" do
      let!(:attendance) { create(:attendance, :finished, user: user, work_on: Date.new(2025,9,1)) }
      let(:method) { :get }
      let(:path)   { edit_user_attendance_path(user, attendance, format: :turbo_stream) }

      it do
        is_expected.to eq 200
        expect(response.media_type).to eq Mime[:turbo_stream]
        expect(response.body).to include(%(action="replace"))
        expect(response.body).to include(%(id="#{ActionView::RecordIdentifier.dom_id(attendance)}"))
      end
    end

    context "PATCH /users/:user_id/attendances/:id/edit_session.turbo_stream（保存）" do
      let!(:attendance) { create(:attendance, user: user, work_on: Date.new(2025,9,1), started_at: Time.zone.parse("2025-09-01 09:00")) }
      let(:method) { :patch }
      let(:path)   { user_attendance_edit_session_path(user, attendance, format: :turbo_stream) }
      let(:params) {{ attendance: { started_at_hm: "10:00", finished_at_hm: "18:00" } }}

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

    context "POST /users/:user_id/attendances.turbo_stream（未登録日の行生成）" do
      let(:method) { :post }
      let(:date)   { Date.new(2025,9,2) }
      let(:path)   { user_attendances_path(user, format: :turbo_stream) }
      let(:params) {{ date: date.to_s }}

      it do
        is_expected.to eq 200
        expect(response.media_type).to eq Mime[:turbo_stream]
        expect(response.body).to include(%(target="attendance-#{date.strftime('%Y%m%d')}"))
        expect(response.body).to include(%(<tr id="attendance_))
      end
    end

    context "DELETE /users/:user_id/attendances/:id/edit_session.turbo_stream（空行のキャンセル）" do
      let!(:attendance) { user.attendances.create!(work_on: Date.new(2025,9,3)) } # 空の新規
      let(:method) { :delete }
      let(:path)   { user_attendance_edit_session_path(user, attendance, format: :turbo_stream) }

      it do
        is_expected.to eq 200
        expect(user.attendances.where(id: attendance.id)).to be_empty
        expect(response.body).to include("未登録").or include("—")
      end
    end
  end
end
