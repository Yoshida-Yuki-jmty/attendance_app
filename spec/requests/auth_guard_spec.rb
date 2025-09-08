require "rails_helper"

RSpec.describe "Auth guard", type: :request do
  let(:user) { create(:user) }

  context "未ログイン時" do
    it "出勤画面（show）へアクセスするとログインへリダイレクト" do
      get user_attendance_path(user)
      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to eq("ログインしてください")
    end

    it "月報（index）へアクセスするとログインへリダイレクト" do
      get user_attendances_path(user)
      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to eq("ログインしてください")
    end

    it "打刻系POST/PATCHもログインへリダイレクト" do
      post  user_attendance_path(user) # 出勤
      expect(response).to redirect_to(new_session_path)

      patch user_attendance_path(user) # 退勤
      expect(response).to redirect_to(new_session_path)
    end
  end

  context "ログイン時" do
    before { sign_in(user) }

    it "出勤画面（show）を表示できる" do
      get user_attendance_path(user)
      expect(response).to have_http_status(:ok)
    end

    it "月報（index）を表示できる" do
      get user_attendances_path(user)
      expect(response).to have_http_status(:ok)
    end

    it "他ユーザIDをURLに入れても中身はcurrent_userベース（少なくとも403/リダイレクトはしない）" do
      other = create(:user)
      get user_attendance_path(other)
      expect(response).to have_http_status(:ok)
    end
  end
end
