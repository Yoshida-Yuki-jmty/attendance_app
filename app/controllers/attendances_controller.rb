class AttendancesController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :require_login
  before_action :_set_attendance, only: [:edit, :update, :cancel_edit, :destroy]

  def index
    @target_month = _target_month
    month_range   = _month_range(@target_month)

    @attendances_by_date = current_user.attendances
                              .where(work_on: month_range)
                              .includes(:breaktimes)
                              .index_by(&:work_on)

    @days_in_month = month_range.to_a
  end

  # 未登録日の編集開始：その日のレコードを作ってフォームに
  def create
    chosen_date = Date.parse(params[:date])
    @attendance = current_user.attendances.find_or_create_by!(work_on: chosen_date)

    # index 上の未登録行は id="attendance-YYYYMMDD" のフォールバックIDで描画している前提
    fallback_id = "attendance-#{chosen_date.strftime('%Y%m%d')}"

    render turbo_stream: turbo_stream.replace(
      fallback_id,
      partial: "attendances/row_form",
      locals: { attendance: @attendance, date: chosen_date }
    )
  end

  # 既存レコードの編集
  def edit
    render turbo_stream: turbo_stream.replace(
      dom_id(@attendance),
      partial: "attendances/row_form",
      locals: { attendance: @attendance, date: @attendance.work_on }
    )
  end

  def update
    update_data    = _attendance_params.to_h
    started_at_hm  = params.dig(:attendance, :started_at_hm)
    finished_at_hm = params.dig(:attendance, :finished_at_hm)
    break_total_hm = params.dig(:attendance, :break_total_hm)

    update_data[:started_at]  = _build_datetime(@attendance.work_on, started_at_hm)  unless started_at_hm.nil?
    update_data[:finished_at] = _build_datetime(@attendance.work_on, finished_at_hm) unless finished_at_hm.nil?

    Attendance.transaction do
      @attendance.update!(update_data)

      # 合計休憩の更新要求が来ているときだけ処理
      unless break_total_hm.nil?
        total_seconds = _parse_hm_to_seconds(break_total_hm)
        if total_seconds < 0
          @attendance.errors.add(:base, I18n.t("activerecord.errors.models.attendance.messages.break_total_negative"))
          raise ActiveRecord::RecordInvalid, @attendance
        end

        # 既存の合計休憩時間を置換
        @attendance.breaktimes.destroy_all

        if total_seconds > 0
          # 合計だけが必要なので「出勤時刻の5時間後」にダミー休憩を１つ作る
          brake_base_time = (@attendance.started_at || Time.zone.parse("#{@attendance.work_on} 9:00")) + 5.hours
          @attendance.breaktimes.create!(started_at: brake_base_time, finished_at: brake_base_time + total_seconds)
        end
      end
    end

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = I18n.t("flash.common.saved")
        render turbo_stream: [
          turbo_stream.replace(
            dom_id(@attendance),
            partial: "attendances/row_display",
            locals: { attendance: @attendance, date: @attendance.work_on, today: business_today }
          ),
          turbo_stream.update("flash", partial: "shared/flash")
        ]
      end
      format.html {
        redirect_to user_attendances_path(
          current_user, 
          month: @attendance.work_on.beginning_of_month
        ), notice: I18n.t("flash.common.saved")
      }
    end

  rescue ActiveRecord::RecordInvalid => e
    respond_to do |format|
      format.turbo_stream do
        flash.now[:alert] = e.record.errors.full_messages.to_sentence.presence || I18n.t("flash.common.save_failed")
        render turbo_stream: [
          turbo_stream.replace(
            dom_id(@attendance),
            partial: "attendances/row_form",
            locals: { attendance: @attendance, date: @attendance.work_on, errors: @attendance.errors }
          ),
          turbo_stream.update("flash", partial: "shared/flash")
        ], status: :unprocessable_entity
      end
      format.html do
        redirect_to user_attendances_path(current_user),
        alert: (e.record.errors.full_messages.to_sentence.presence || I18n.t("flash.common.save_failed"))
      end
    end
  end

def destroy
  @attendance = current_user.attendances.find(params[:id])
  selected_business_date  = @attendance.work_on
  target = dom_id(@attendance) 
  @attendance.destroy                         
  business_today = Attendance.business_date(Time.zone.now)

  render turbo_stream: turbo_stream.replace(
    target,
    partial: "attendances/row_display",
    locals: { attendance: nil, date: selected_business_date, today: business_today }  
  )
end

  private

  def _set_attendance
    @attendance = current_user.attendances.find(params[:id])
  end

  def _attendance_params
    params.require(:attendance).permit(:started_at, :finished_at)
  end

  def _build_datetime(date, hm)
    return nil if hm.blank?
    Time.zone.parse("#{date} #{hm}")
  end

  def _parse_hm_to_seconds(hm)
    return 0 if hm.blank?
    unless hm =~ /\A\d{1,2}:\d{2}\z/
      # update内で rescue しているので ActiveRecord::RecordInvalid を投げてOK
      raise ActiveRecord::RecordInvalid.new(@attendance), I18n.t("activerecord.errors.models.attendance.messages.break_total_format")
    end
    h, m = hm.split(":").map!(&:to_i)
    h * 3600 + m * 60
  end

  def _target_month
    raw = params[:month].presence
    date =
      if raw&.match?(/\A\d{4}-\d{2}\z/)
        Date.strptime(raw, "%Y-%m")
      else
        begin
          raw ? Date.parse(raw) : Date.current
        rescue ArgumentError
          Date.current
        end
      end
    date.beginning_of_month
  end

  def _month_range(month)
    month..month.end_of_month
  end
end

