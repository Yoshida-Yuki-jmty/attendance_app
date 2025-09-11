require 'rails_helper'

RSpec.describe "Breaktimes", type: :request do
  let(:user) { create(:user) }
  before { sign_in(user) }

  context "POST /users/:user_id/breaktimes" do
    let(:method) { :post }
    let(:path)   { user_breaktimes_path(user) }

    before { Attendance.clock_in!(user) }

    it do
      expect { is_expected.to eq 302 }.to change { user.breaktimes.count }.by(1)
      expect(response).to redirect_to(user_current_attendance_path(user))
    end
  end

  context "PATCH /users/:user_id/breaktimes/:id" do
    let(:method) { :patch }
    let(:bt)     { user.tap { Attendance.clock_in!(user) ; post user_breaktimes_path(user) }.breaktimes.last }
    let(:path)   { user_breaktime_path(user, bt) }

    it do
      is_expected.to eq 302
      expect(bt.reload.finished_at).to be_present
      expect(response).to redirect_to(user_current_attendance_path(user))
    end
  end

end
