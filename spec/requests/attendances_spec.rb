require 'rails_helper'

RSpec.describe "Attendances", type: :request do
  let(:user) { create(:user) }

  describe "GET /" do
    let(:method) { :get }
    let(:path)   { root_path }

    context "未ログインの場合" do
      it do
        is_expected.to eq 302
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "ログイン済の場合" do
      before { sign_in(user) }
      it { is_expected.to eq 200 }
    end
  end

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

  describe "GET /users/:user_id/attendances" do
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

    context "月指定で異常値が指定された場合" do
      before { sign_in(user) }
      let(:method) { :get }

      context "month が不正な場合" do
        let(:path) { user_attendances_path(user, month: "hoge") }
        it do
          is_expected.to eq 200
          expect(response.body).to include(%(<turbo-frame id="selected-month">))
        end
      end

      context "YYYY-MM 形式（不正）の場合" do
        let(:path) { user_attendances_path(user, month: Date.current.strftime("%Y-%m")) }
        it { is_expected.to eq 200 }
      end
    end
  end

  describe "POST /users/:user_id/attendances.turbo_stream" do
    let(:method) { :post }
    let(:date)   { Date.new(2025,9,2) }
    let(:path)   { user_attendances_path(user, format: :turbo_stream) }
    let(:params) {{ date: date.to_s }}

    context '未ログインの場合' do
      it do
        is_expected.to eq 302
        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq("ログインしてください").or be_present
      end
    end

    context '勤怠未登録のレコードの場合' do
      before { sign_in(user) }
      it do
        is_expected.to eq 200
        expect(response.media_type).to eq Mime[:turbo_stream]
        expect(response.body).to include(%(target="attendance-#{date.strftime('%Y%m%d')}"))
        expect(response.body).to include(%(<tr id="attendance_))          
      end
    end
    
    context '既存の勤怠レコードの場合' do
      before { sign_in(user) }
      before { create(:attendance, user: user, work_on: date) }
      it "新規作成はせずフォームを返す" do
        expect {
          is_expected.to eq 200
        }.not_to change { user.attendances.where(work_on: date).count }
        
        expect(response.media_type).to eq Mime[:turbo_stream]
        # create アクションは既存でも fallback_id を置き換える
        expect(response.body).to include(%(target="attendance-#{date.strftime('%Y%m%d')}"))
        expect(response.body).to include(%(<tr id="attendance_))
      end
    end
  end

  describe "GET /users/:user_id/attendances/:id/edit.turbo_stream" do
    let!(:attendance) { create(:attendance, :finished, user: user, work_on: Date.new(2025,9,1)) }
    let(:method) { :get }
    let(:path)   { edit_user_attendance_path(user, attendance, format: :turbo_stream) }

    context '未ログインの場合' do
      it do
        is_expected.to eq 302
        expect(response).to redirect_to(new_session_path)
      end      
    end

    context "ログイン済の場合" do
      before { sign_in(user) }
      it do
        is_expected.to eq 200
        expect(response.media_type).to eq Mime[:turbo_stream]
        expect(response.body).to include(%(action="replace"))
        expect(response.body).to include(%(id="#{ActionView::RecordIdentifier.dom_id(attendance)}"))
      end
    end
  end

  describe "DELETE /users/:user_id/attendances/:id" do
    let(:method) { :delete }
    let(:path)   { user_attendance_path(user, attendance, format: :turbo_stream) }
    let!(:attendance) { create(:attendance, user: user, work_on: Date.new(2025,9,4)) }

    context "未ログインの場合" do
      it do
        is_expected.to eq 302
        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq("ログインしてください").or be_present
      end
    end
    
    context "ログイン済の場合" do
      before { sign_in(user) }
      it do
        expect { is_expected.to eq 200 }.to change { user.attendances.exists?(attendance.id) }.from(true).to(false)
        expect(response.media_type).to eq Mime[:turbo_stream]
        expect(response.body).to include("未登録").or include("—")
      end
    end        
  end
end

