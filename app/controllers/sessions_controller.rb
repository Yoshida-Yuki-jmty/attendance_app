class SessionsController < ApplicationController
  def new
    redirect_to user_current_attendance_path(current_user) if logged_in?
  end

  def create
    if logged_in?
      redirect_to user_current_attendance_path(current_user),notice: 'すでにログイン済みです'
    else
      user = User.find_by(email: params[:email])
      if user&.authenticate(params[:password])
        log_in(user)
        redirect_to user_current_attendance_path(user), notice: 'ログインしました'
      else
        flash.now[:alert] = 'メールまたはパスワードが違います'
        render :new, status: :unprocessable_entity
      end
    end
  end

  def destroy
    log_out
    redirect_to new_session_path, notice: 'ログアウトしました'
  end
end
