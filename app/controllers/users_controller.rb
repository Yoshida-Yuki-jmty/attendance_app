class UsersController < ApplicationController
  before_action :require_login, except: %i[new create]
  before_action :_set_user, only: %i[show edit update]
  before_action -> { require_current_user!(@user) }, only: %i[show edit update]

  def show
  end

  def new
    @user = User.new
  end

  def edit
  end

  def create
    @user = User.new(_user_params)
    if @user.save
      redirect_to new_session_path, notice: I18n.t('flash.users.created')
    else
      flash.now[:alert] = I18n.t('flash.users.create_failed')
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @user.update(_user_params)
      redirect_to @user, notice: I18n.t('flash.users.updated')
    else
      flash.now[:alert] = I18n.t('flash.users.update_failed')
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def _set_user
    @user = User.find(params[:id])
  end

  def _user_params
    params.require(:user).permit(:name, :email, :password, :password_digest)
  end
end
