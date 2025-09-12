require 'rails_helper'

RSpec.describe 'Breaktimes', type: :request do
  let(:user) { create(:user) }
  before { sign_in(user) }

  context 'POST /users/:user_id/breaktimes' do
    let(:method) { :post }
    let(:path)   { user_breaktimes_path(user) }

    context '出勤済の場合' do
      before { Attendance.clock_in!(user: user) }
      it do
        expect { is_expected.to eq 302 }.to change { user.breaktimes.count }.by(1)
        expect(response).to redirect_to(user_current_attendance_path(user))
      end
    end

    context '未出勤の場合' do
      it do
        is_expected.to eq 302
        expect(response).to redirect_to(user_current_attendance_path(user))
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe 'PATCH /users/:user_id/breaktimes/:id' do
    let(:method) { :patch }
    let(:breaktime) do
      user.tap do
        Attendance.clock_in!(user: user)
        post user_breaktimes_path(user)
      end.breaktimes.last
    end
    let(:path) { user_breaktime_path(user, breaktime) }
    context '退勤前の場合' do
      it do
        is_expected.to eq 302
        expect(breaktime.reload.finished_at).to be_present
        expect(response).to redirect_to(user_current_attendance_path(user))
      end
    end

    context '退勤済の場合' do
      before do
        Attendance.clock_in!(user: user)
        post user_breaktimes_path(user)
        user.breaktimes.last.update!(finished_at: Time.zone.now)
      end
      let(:breaktime) { user.breaktimes.last }
      it do
        is_expected.to eq 302
        expect(flash[:alert]).to be_present
      end
    end
  end
end
