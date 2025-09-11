require 'rails_helper'

RSpec.describe 'Users', type: :request do
  let(:user) { create(:user) }

  describe 'GET /users/new' do
    let(:method) { :get }
    let(:path)   { new_user_path }

    it '新規登録フォームが表示される' do
      is_expected.to eq 200
      expect(response.body).to include('登録')
    end
  end

  describe 'POST /users' do
    let(:method) { :post }
    let(:path)   { users_path }
    let(:params) { { user: attributes_for(:user) } }

    it 'ユーザー作成に成功する' do
      expect { is_expected.to eq 302 }.to change(User, :count).by(1)
      expect(response).to redirect_to(new_session_path)
      expect(flash[:notice]).to be_present
    end

    context '無効な値の場合' do
      let(:params) { { user: { name: '', email: '', password: '' } } }
      it do
        is_expected.to eq 422
        expect(response.body).to include('登録')
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe 'GET /users/:id' do
    let(:method) { :get }
    let(:path)   { user_path(user) }

    context '未ログインの場合' do
      it do
        is_expected.to eq 302
        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'ログイン済の場合' do
      before { sign_in(user) }
      it { is_expected.to eq 200 }
    end
  end

  describe 'GET /users/:id/edit' do
    let(:method) { :get }
    let(:path)   { edit_user_path(user) }

    context '未ログインの場合' do
      it do
        is_expected.to eq 302
        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'ログイン済の場合' do
      before { sign_in(user) }
      it { is_expected.to eq 200 }
    end
  end

  describe 'PATCH /users/:id' do
    let(:method) { :patch }
    let(:path)   { user_path(user) }
    let(:params) { { user: { name: 'Updated' } } }

    context '未ログインの場合' do
      it do
        is_expected.to eq 302
        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'ログイン済の場合' do
      before { sign_in(user) }

      it '更新できる' do
        is_expected.to eq 302
        expect(user.reload.name).to eq 'Updated'
        expect(response).to redirect_to(user_path(user))
        expect(flash[:notice]).to be_present
      end

      context '無効な値の場合' do
        let(:params) { { user: { email: '' } } }
        it do
          is_expected.to eq 422
          expect(flash[:alert]).to be_present
        end
      end
    end
  end
end
