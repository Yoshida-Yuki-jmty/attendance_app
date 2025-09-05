class SessionsController < ApplicationController
  def new
    redirect_to user_path(current_user) if logged_in?
  end

  def create
    user = User.find_by(email: params[:email])
    if user&.authenticate(params[:password])
      log_in(user)
      redirect_to user_path(user), notice: 'ログインしました'
    else
      flash.now[:alert] = 'メールまたはパスワードが違います'
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    log_out
    redirect_to new_session_path, notice: 'ログアウトしました'
  end

  private

  def no_store!
    response.headers['Cache-Control'] = 'no-store'
  end
end
