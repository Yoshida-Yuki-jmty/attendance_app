class AttendancesController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :require_login

  def index
    raw = params[:month].presence
    @month =
      if raw
        if raw.match?(/\A\d{4}-\d{2}\z/)
          Date.strptime(raw, "%Y-%m")
        else
          Date.parse(raw)
        end.beginning_of_month
      else
        Date.current.beginning_of_month
      end
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
    @today        = current_user.attendances.includes(:breaktimes).find_or_initialize_by(work_date: bizdate)
    @opened_break = @today&.breaktimes&.opened&.first
  end

  def update
    Attendance.clock_out!(current_user)
    redirect_to root_path, notice: t("attendances.notices.clocked_out")
  rescue Attendance::NoClockInError => e
    redirect_to root_path, alert: e.message
  rescue ActiveRecord::RecordInvalid => e
    redirect_to root_path, alert: e.record.errors.full_messages.to_sentence
  end


  # 既存レコードの編集
  def edit_row
    @attendance = current_user.attendances.find(params[:id])
    render turbo_stream: turbo_stream.replace(
      dom_id(@attendance),
      partial: "attendances/row_form",
      locals: { a: @attendance, d: @attendance.work_date }
    )
  end

  # 未登録日の編集開始：その日のレコードを作ってフォームに
  def build_row
    date = Date.parse(params[:date])
    @attendance = current_user.attendances.find_or_create_by!(work_date: date)

    # index 上の未登録行は id="attendance-YYYYMMDD" のフォールバックIDで描画している前提
    fallback_id = "attendance-#{date.strftime('%Y%m%d')}"

    render turbo_stream: turbo_stream.replace(
      fallback_id,
      partial: "attendances/row_form",
      locals: { a: @attendance, d: date }
    )
  end

  def save_row
    @attendance = current_user.attendances.find(params[:id])

    attrs = row_params.to_h # ← 既存(datetime)が来た場合に備えて取り込む（空なら無視）
    # 時刻のみのパラメータを日付と合成
    started_hm  = params.dig(:attendance, :started_at_hm)
    finished_hm = params.dig(:attendance, :finished_at_hm)

    attrs[:started_at]  = build_dt(@attendance.work_date, started_hm)  if !started_hm.nil?
    attrs[:finished_at] = build_dt(@attendance.work_date, finished_hm) if !finished_hm.nil?

    @attendance.update!(attrs)

    @today = Attendance.business_date(Time.zone.now)
    render turbo_stream: turbo_stream.replace(
      dom_id(@attendance),
      partial: "attendances/row_display",
      locals: { a: @attendance, d: @attendance.work_date, today: @today }
    )
  rescue ActiveRecord::RecordInvalid => e
    render turbo_stream: turbo_stream.replace(
      dom_id(@attendance),
      partial: "attendances/row_form",
      locals: { a: @attendance, d: @attendance.work_date, errors: e.record.errors }
    )
  end

  def cancel_row
    @attendance = current_user.attendances.find(params[:id])
    date  = @attendance.work_date
    @today = Attendance.business_date(Time.zone.now)

    # 編集開始時に新規作成しただけで空のままなら削除して未登録表示に戻す
    if @attendance.started_at.blank? && @attendance.finished_at.blank? && @attendance.breaktimes.blank?
      # 置換ターゲットは今の <tr id="dom_id(@attendance)">
      target_id = dom_id(@attendance)
      @attendance.destroy
      return render turbo_stream: turbo_stream.replace(
        target_id,
        partial: "attendances/row_display",
        locals: { a: nil, d: date, today: @today } # ← 未登録表示に戻す
      )
    end

    # 既存レコードなら普通に表示に戻す
    render turbo_stream: turbo_stream.replace(
      dom_id(@attendance),
      partial: "attendances/row_display",
      locals: { a: @attendance, d: date, today: @today }
    )
  end

  private

  def row_params
    params.require(:attendance).permit(:started_at, :finished_at)
  end

  def build_dt(date, hm)
    return nil if hm.blank?
    Time.zone.parse("#{date} #{hm}")
  end
end

