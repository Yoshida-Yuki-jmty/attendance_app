module SessionAuth
  extend ActiveSupport::Concern

  included do
    helper_method :current_user,
                  :logged_in?,
                  :current_user?,
                  :logged_in_user?
  end


  # --- セッション制御 ---
  def log_in(user)
    reset_session
    session[:user_id] = user.id
  end

  def log_out
    reset_session
  end

  # --- 状態判定 ---
  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def current_user?(user)
    current_user&.id == user&.id
  end

  def logged_in?
    current_user.present?
  end

  def logged_in_user?(user = nil)
    user ||= @user
    logged_in? && current_user?(user)
  end

  def require_login
    redirect_to new_session_path, alert: 'ログインしてください' unless logged_in?
  end

  def require_current_user!(user = nil)
    user ||= @user
    return if logged_in_user?(user)
    redirect_to new_session_path, alert: '権限がありません'
  end
end
