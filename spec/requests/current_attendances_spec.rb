# spec/requests/current_attendances_spec.rb
require 'rails_helper'

RSpec.describe "CurrentAttendances", type: :request do
  let(:user) { create(:user) }

  before { sign_in(user) }

  describe "GET /users/:user_id/current_attendance" do
    it "returns http success" do
      get user_current_attendance_path(user)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /users/:user_id/current_attendance (clock in)" do
    it "redirects to root after clock-in" do
      post user_current_attendance_path(user)
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("出勤") # 文言は適宜
    end
  end

  describe "PATCH /users/:user_id/current_attendance (clock out)" do
    it "redirects to root after clock-out" do
      # 退勤テスト前に出勤しておく
      post user_current_attendance_path(user)

      patch user_current_attendance_path(user)
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("退勤") # 文言は適宜
    end
  end
end
