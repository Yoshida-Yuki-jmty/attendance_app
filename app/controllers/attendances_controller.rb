class AttendancesController < ApplicationController
  before_action :require_login

  def index
    @month  = (params[:month] ? Date.parse(params[:month]) : Date.current).beginning_of_month
    @today  = Attendance.business_date(Time.zone.now)
    range   = @month..@month.end_of_month

    @att_by_date = current_user.attendances
                      .where(work_date: range)
                      .includes(:breaktimes)
                      .index_by(&:work_date)

    @days = range.to_a
  end

  def create
    Attendance.clock_in!(current_user)
    redirect_to root_path, notice: t("attendances.notices.clocked_in")
  rescue Attendance::AlreadyClockedOutError, Attendance::AlreadyClockedInError => e
    redirect_to root_path, alert: e.message
  rescue ActiveRecord::RecordInvalid => e
    redirect_to root_path, alert: e.record.errors.full_messages.to_sentence
  end

  def show
    bizdate       = Attendance.business_date(Time.zone.now)
    @today        = current_user.attendances.includes(:breaktimes).find_by(work_date: bizdate)
    @opened_break = @today&.breaktimes&.opened&.first
    @user         = current_user
  end

  def update
    Attendance.clock_out!(current_user)
    redirect_to root_path, notice: t("attendances.notices.clocked_out")
  rescue Attendance::NoClockInError => e
    redirect_to root_path, alert: e.message
  rescue ActiveRecord::RecordInvalid => e
    redirect_to root_path, alert: e.record.errors.full_messages.to_sentence
  end
end

