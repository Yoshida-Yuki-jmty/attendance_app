class AttendancesController < ApplicationController
  include ActionView::RecordIdentifier
  include Saveable

  before_action :require_login
  before_action :_set_attendance, only: %i[edit update destroy]

  def index
    @target_month = _target_month
    range = _month_range(@target_month)

    @attendances_by_date = current_user.attendances
                                       .where(work_on: range)
                                       .includes(:breaktimes)
                                       .index_by(&:work_on)

    @days_in_month = range.to_a
  end

  # 既存レコードの編集
  def edit
    render turbo_stream: turbo_stream.replace(
      dom_id(@attendance),
      partial: 'attendances/row_form',
      locals: { attendance: @attendance, date: @attendance.work_on }
    )
  end

  # 未登録日の編集開始：その日のレコードを作ってフォームに
  def create
    chosen_date = Date.parse(params[:date])
    @attendance = current_user.attendances.find_or_create_by!(work_on: chosen_date)

    # index 上の未登録行は id="attendance-YYYYMMDD" のフォールバックIDで描画している前提
    fallback_id = "attendance-#{chosen_date.strftime('%Y%m%d')}"

    render turbo_stream: turbo_stream.replace(
      fallback_id,
      partial: 'attendances/row_form',
      locals: { attendance: @attendance, date: chosen_date }
    )
  end

  def update
    unless unregistered?(@attendance)
      return respond_to do |format|
        format.turbo_stream do
          flash.now[:alert] = I18n.t('flash.common.use_edit_session')
          render turbo_stream: turbo_stream.update('flash', partial: 'shared/flash'), status: :unprocessable_entity
        end
        format.html { head :unprocessable_entity }
      end
    end

    apply_attendance_update!(@attendance)

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = I18n.t('flash.common.saved')
        render turbo_stream: [
          turbo_stream.replace(
            dom_id(@attendance),
            partial: 'attendances/row_display',
            locals: { attendance: @attendance, date: @attendance.work_on, today: business_today }
          ),
          turbo_stream.update('flash', partial: 'shared/flash')
        ]
      end
      format.html do
        redirect_to user_attendances_path(current_user, month: @attendance.work_on.beginning_of_month),
                    notice: I18n.t('flash.common.saved')
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    respond_to do |format|
      format.turbo_stream do
        flash.now[:alert] = e.record.errors.full_messages.to_sentence.presence || I18n.t('flash.common.save_failed')
        render turbo_stream: [
          turbo_stream.replace(
            dom_id(@attendance),
            partial: 'attendances/row_form',
            locals: { attendance: @attendance, date: @attendance.work_on, errors: @attendance.errors }
          ),
          turbo_stream.update('flash', partial: 'shared/flash')
        ], status: :unprocessable_entity
      end
      format.html do
        redirect_to user_attendances_path(current_user),
                    alert: e.record.errors.full_messages.to_sentence.presence || I18n.t('flash.common.save_failed')
      end
    end
  end

  def destroy
    selected_date = @attendance.work_on
    target = dom_id(@attendance)
    @attendance.destroy
    business_today = Attendance.business_date(Time.zone.now)

    render turbo_stream: turbo_stream.replace(
      target,
      partial: 'attendances/row_display',
      locals: { attendance: nil, date: selected_date, today: business_today }
    )
  end

  private

  def _set_attendance
    @attendance = current_user.attendances.find(params[:id])
  end

  def _attendance_params
    params.require(:attendance).permit(:started_at, :finished_at)
  end

  def _target_month
    raw = params[:month].presence
    date =
      if raw&.match?(/\A\d{4}-\d{2}\z/)
        Date.strptime(raw, '%Y-%m')
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
