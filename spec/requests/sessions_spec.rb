require 'rails_helper'

RSpec.describe 'Sessions', type: :request do

  # ログイン・ログアウトのリクエストスペック
  let(:user) { create(:user) }

  describe "GET /session/new" do
    it "未ログインなら200でログイン画面を表示" do
      get new_session_path
      expect(response).to have_http_status(:ok)
    end

    it "ログイン済みなら勤怠一覧画面へリダイレクト" do
      sign_in(user)
      get new_session_path
      expect(response).to redirect_to(user_current_attendance_path(user))
    end
  end

  describe "POST /session" do
    it "正しい資格情報でログインできる" do
      post session_path, params: { email: user.email, password: "password" }
      expect(response).to redirect_to(user_current_attendance_path(user))
      follow_redirect!
      # 保護ページにアクセスしてもリダイレクトされないことを以後のテストで確認する
      get user_current_attendance_path(user)
      expect(response).to have_http_status(:ok)
    end

    it "誤った資格情報なら422で再表示＆フラッシュ" do
      post session_path, params: { email: user.email, password: "wrong" }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(flash[:alert]).to eq("メールまたはパスワードが違います")
    end
  end

  describe "DELETE /session" do
    it "ログアウトでき、新規ログイン画面へリダイレクト" do
      sign_in(user)
      delete session_path
      expect(response).to redirect_to(new_session_path)

      # ログアウト後は保護ページに行くとログイン画面へ飛ばされる
      get user_current_attendance_path(user)
      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to eq("ログインしてください")
    end
  end
end
