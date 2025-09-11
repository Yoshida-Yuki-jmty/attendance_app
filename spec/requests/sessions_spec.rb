require 'rails_helper'

RSpec.describe 'Sessions', type: :request do
  let(:user) { create(:user) }

  context "GET /session/new" do
    let(:method) { :get }
    let(:path)   { new_session_path }

    context "未ログインの場合" do
      it { is_expected.to eq 200 }
    end

    context "ログイン済の場合" do
      before { sign_in(user) }
      it do
        is_expected.to eq 302
        expect(response).to redirect_to(user_current_attendance_path(user))
      end
    end
  end

  context "POST /session" do
    let(:method) { :post }
    let(:path)   { session_path }

    context "ログイン情報が正しい場合" do
      let(:params) {{ email: user.email, password: "password" }}
      it do
        is_expected.to eq 302
        expect(response).to redirect_to(user_current_attendance_path(user))
        follow_redirect!
        get user_current_attendance_path(user)
        expect(response).to have_http_status(:ok)
      end
    end

    context "ログイン情報が誤っている場合" do
      let(:params) {{ email: user.email, password: "wrong" }}
      it do
        is_expected.to eq 422
        expect(flash[:alert]).to eq("メールまたはパスワードが違います")
      end
    end
  end

  context "DELETE /session" do
    before { sign_in(user) }
    let(:method) { :delete }
    let(:path)   { session_path }
    it do
      is_expected.to eq 302
      expect(response).to redirect_to(new_session_path)

      get user_current_attendance_path(user)
      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to eq("ログインしてください")
    end
  end
end
