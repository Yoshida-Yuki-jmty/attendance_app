module Attendances
  class EditSessionsController < ApplicationController
    include ActionView::RecordIdentifier
    include Saveable

    before_action :require_login
    before_action :_set_attendance

    # 登録済みレコードの保存
    # PATCH /users/:user_id/attendances/:attendance_id/edit_session
    def update
      apply_attendance_update!(@attendance)

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
        format.html do
          redirect_to user_attendances_path(current_user, month: @attendance.work_on.beginning_of_month),
                      notice: I18n.t("flash.common.saved")
        end
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

    # 編集破棄：空なら消して未登録表示／既存なら表示へ戻す
    # DELETE /users/:user_id/attendances/:attendance_id/edit_session
    def destroy
      attendance = current_user.attendances.find(params[:attendance_id])
      selected   = attendance.work_on
      target_id  = dom_id(attendance)

      if attendance.started_at.blank? && attendance.finished_at.blank? && attendance.breaktimes.blank?
        attendance.destroy
        render turbo_stream: turbo_stream.replace(
          target_id,
          partial: "attendances/row_display",
          locals: { attendance: nil, date: selected, today: business_today }
        )
      else
        render turbo_stream: turbo_stream.replace(
          target_id,
          partial: "attendances/row_display",
          locals: { attendance: attendance, date: selected, today: business_today }
        )
      end
    end

    private
    def _set_attendance
      @attendance = current_user.attendances.find(params[:attendance_id])
    end

  end
end
