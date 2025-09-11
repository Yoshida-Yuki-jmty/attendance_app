# spec/requests/current_attendances_spec.rb
require 'rails_helper'

RSpec.describe 'CurrentAttendances', type: :request do
  let(:user) { create(:user) }

  context 'GET /users/:user_id/current_attendance' do
    let(:method) { :get }
    let(:path)   { user_current_attendance_path(user) }

    context '未ログインの場合' do
      it { is_expected.to eq 302 }
    end

    context 'ログイン済の場合' do
      before { sign_in(user) }
      it do
        is_expected.to eq 200
        expect(response.body).to include('本日の日報')
      end
    end
  end

  context 'POST /users/:user_id/attendance' do
    let(:method) { :post }
    let(:path)   { user_current_attendance_path(user) }

    context '未ログインの場合' do
      it { is_expected.to eq 302 }
    end

    context 'ログイン済の場合' do
      before { sign_in(user) }
      it do
        expect { is_expected.to eq 302 }.to change { user.attendances.count }.by(1)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'PATCH /users/:user_id/current_attendance' do
    let(:method) { :patch }
    let(:path)   { user_current_attendance_path(user) }

    context '未ログインの場合' do
      it do
        is_expected.to eq 302
        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'ログイン済かつ、出勤済の場合' do
      before do
        sign_in(user)
        Attendance.clock_in!(user)
      end
      let(:method) { :patch }
      let(:path)   { user_current_attendance_path(user) }

      it do
        expect { is_expected.to eq 302 }.to change { user.attendances.where.not(finished_at: nil).count }.by(1)
        expect(response).to redirect_to(root_path)
      end
    end

    context 'ログイン済かつ、出勤未登録の場合' do
      before { sign_in(user) }
      let(:method) { :patch }
      let(:path)   { user_current_attendance_path(user) }

      it '退勤できずエラーやリダイレクトになる' do
        is_expected.to eq 302
        expect(flash[:alert]).to be_present.or be_nil
      end
    end
  end
end
