class SessionsController < ApplicationController
  def new
    redirect_to user_current_attendance_path(current_user) if logged_in?
  end

  def create
    if logged_in?
      redirect_to user_current_attendance_path(current_user),notice: I18n.t("flash.sessions.already_logged_in")
    else
      user = User.find_by(email: params[:email])
      if user&.authenticate(params[:password])
        log_in(user)
        redirect_to user_current_attendance_path(user), notice: I18n.t("flash.sessions.logged_in")
      else
        flash.now[:alert] = I18n.t("flash.sessions.invalid_credentials")
        render :new, status: :unprocessable_entity
      end
    end
  end

  def destroy
    log_out
    redirect_to new_session_path, notice: I18n.t("flash.sessions.logged_out")
  end
end
