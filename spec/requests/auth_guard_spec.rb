require 'rails_helper'

RSpec.describe 'Auth guard', type: :request do
  let(:user) { create(:user) }

  context 'GET /users/:user_id/attendance' do
    context '未ログインの場合' do
      let(:method) { :get }
      let(:path)   { user_current_attendance_path(user) }
      it do
        is_expected.to eq 302
        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq('ログインしてください')
      end
    end

    context 'ログイン済の場合' do
      before { sign_in(user) }
      let(:method) { :get }
      let(:path)   { user_current_attendance_path(user) }
      it { is_expected.to eq 200 }
    end
  end

  context 'GET /users/:user_id/attendances' do
    context '未ログインの場合' do
      let(:method) { :get }
      let(:path)   { user_attendances_path(user) }
      it do
        is_expected.to eq 302
        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq('ログインしてください')
      end
    end

    context 'ログイン済の場合' do
      before { sign_in(user) }
      let(:method) { :get }
      let(:path)   { user_attendances_path(user) }
      it { is_expected.to eq 200 }
    end
  end

  context 'POST /users/:user_id/attendance' do
    context '自身のユーザーIDのリクエストをする場合' do
      let(:method) { :post }
      let(:path)   { user_current_attendance_path(user) }

      context '未ログインの場合' do
        it do
          is_expected.to eq 302
          expect(response).to redirect_to(new_session_path)
        end
      end

      context 'ログイン済の場合' do
        before { sign_in(user) }
        it do
          expect { is_expected.to eq 302 }.to change { user.attendances.count }.by(1)
          expect(response).to redirect_to(root_path)
        end
      end
    end

    context '他ユーザーIDのリクエストをする場合' do
      before { sign_in(user) }
      let(:method) { :post }
      let(:other)  { create(:user) }
      let(:path)   { user_current_attendance_path(other) }
      it '自分のユーザーIDに対応するページにリダイレクトする' do
        expect { is_expected.to eq 302 }.to change { user.attendances.count }.by(1)
        expect(response).to redirect_to(root_path)
        expect(other.attendances.count).to eq(0)
      end
    end
  end

  context 'PATCH /users/:user_id/attendance' do
    let(:method) { :patch }
    let(:path)   { user_current_attendance_path(user) }
    it do
      is_expected.to eq 302
      expect(response).to redirect_to(new_session_path)
    end
  end
end
