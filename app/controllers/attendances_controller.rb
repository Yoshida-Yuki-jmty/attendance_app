class AttendancesController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :require_login
  before_action :_set_attendance, only: [:edit, :update, :cancel_row, :destroy]

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

  # 未登録日の編集開始：その日のレコードを作ってフォームに
  def create
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

  # 既存レコードの編集
  def edit
    render turbo_stream: turbo_stream.replace(
      dom_id(@attendance),
      partial: "attendances/row_form",
      locals: { a: @attendance, d: @attendance.work_date }
    )
  end

  def update
    attrs = _row_params.to_h
    # 時刻のみのパラメータを日付と合成
    started_hm     = params.dig(:attendance, :started_at_hm)
    finished_hm    = params.dig(:attendance, :finished_at_hm)
    break_total_hm = params.dig(:attendance, :break_total_hm)

    attrs[:started_at]  = _build_dt(@attendance.work_date, started_hm)  unless started_hm.nil?
    attrs[:finished_at] = _build_dt(@attendance.work_date, finished_hm) unless finished_hm.nil?

    Attendance.transaction do
      @attendance.update!(attrs)

      # 合計休憩の更新要求が来ているときだけ処理
      unless break_total_hm.nil?
        total_seconds = _parse_hm_to_seconds(break_total_hm)
        if total_seconds < 0
          @attendance.errors.add(:base, "休憩は 00:00 以上で入力してください")
          raise ActiveRecord::RecordInvalid, @attendance
        end

        # 既存の合計休憩時間を置換
        @attendance.breaktimes.destroy_all

        if total_seconds > 0
          # 合計だけが必要なので「出勤時刻の5時間後」にダミー休憩を１つ作る
          base = (@attendance.started_at || Time.zone.parse("#{@attendance.work_date} 9:00")) + 5.hours
          @attendance.breaktimes.create!(started_at: base, finished_at: base + total_seconds)
        end
      end
    end

    @today = Attendance.business_date(Time.zone.now)

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "保存しました"
        render turbo_stream: [
          turbo_stream.replace(
            dom_id(@attendance),
            partial: "attendances/row_display",
            locals: { a: @attendance, d: @attendance.work_date, today: @today }
          ),
          turbo_stream.update("flash", partial: "shared/flash")
        ]
      end
      format.html {
        redirect_to user_attendances_path(
          current_user, 
          month: @attendance.work_date.beginning_of_month
        )
      }
    end

  rescue ActiveRecord::RecordInvalid => e
    respond_to do |format|
      format.turbo_stream do
        flash.now[:alert] = e.record.errors.full_messages.to_sentence.presence || "保存に失敗しました"
        render turbo_stream: [
          turbo_stream.replace(
            dom_id(@attendance),
            partial: "attendances/row_form",
            locals: { a: @attendance, d: @attendance.work_date, errors: @attendance.errors }
          ),
          turbo_stream.update("flash", partial: "shared/flash")
        ], status: :unprocessable_entity
      end
      format.html do
        redirect_to user_attendances_path(current_user),
        alert: e.record.errors.full_messages.to_sentence
      end
    end
  end

  # フォーム編集の破棄
  def cancel_row
    @attendance = current_user.attendances.find(params[:id])
    date  = @attendance.work_date
    @today = Attendance.business_date(Time.zone.now)

    # 編集開始時に新規作成しただけで空のままなら削除して未登録表示に戻す
    if @attendance.started_at.blank? && @attendance.finished_at.blank? && @attendance.breaktimes.blank?
      target_id = dom_id(@attendance)
      @attendance.destroy
      return render turbo_stream: turbo_stream.replace(
        target_id,
        partial: "attendances/row_display",
        locals: { a: nil, d: date, today: @today }
      )
    end

    # 既存レコードなら普通に表示に戻す
    render turbo_stream: turbo_stream.replace(
      dom_id(@attendance),
      partial: "attendances/row_display",
      locals: { a: @attendance, d: date, today: @today }
    )
  end

def destroy
  @attendance = current_user.attendances.find(params[:id])
  date   = @attendance.work_date
  target = dom_id(@attendance) 
  @attendance.destroy                         
  @today = Attendance.business_date(Time.zone.now)

  render turbo_stream: turbo_stream.replace(
    target,
    partial: "attendances/row_display",
    locals: { a: nil, d: date, today: @today }  
  )
end

  private

  def _set_attendance
    @attendance = current_user.attendances.find(params[:id])
  end

  def _row_params
    params.require(:attendance).permit(:started_at, :finished_at)
  end

  def _build_dt(date, hm)
    return nil if hm.blank?
    Time.zone.parse("#{date} #{hm}")
  end

  def _parse_hm_to_seconds(hm)
    return 0 if hm.blank?
    unless hm =~ /\A\d{1,2}:\d{2}\z/
      # update内で rescue しているので ActiveRecord::RecordInvalid を投げてOK
      raise ActiveRecord::RecordInvalid.new(@attendance), "休憩は HH:MM 形式で入力してください"
    end
    h, m = hm.split(":").map!(&:to_i)
    h * 3600 + m * 60
  end
end

