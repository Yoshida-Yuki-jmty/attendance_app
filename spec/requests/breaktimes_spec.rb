require 'rails_helper'

RSpec.describe "Breaktimes", type: :request do
  let(:user) { create(:user) }

  before { sign_in(user) }

  it "POST /users/:user_id/breaktimes で休憩開始できる" do
    Attendance.clock_in!(user)

    expect {
      post user_breaktimes_path(user)
    }.to change { user.breaktimes.count }.by(1)

    expect(response).to redirect_to(user_current_attendance_path(user))
  end

  it "PATCH /users/:user_id/breaktimes/:id で休憩終了できる" do
    Attendance.clock_in!(user)
    post user_breaktimes_path(user)
    bt = user.breaktimes.last

    patch user_breaktime_path(user, bt)
    expect(bt.reload.finished_at).to be_present
    expect(response).to redirect_to(user_current_attendance_path(user))
  end

end
