# For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
Rails.application.routes.draw do
  root 'current_attendances#show'

  resources :users, except: [:index, :destroy] do
    resource  :current_attendance, only: [:create, :show, :update]
    resources :attendances, except: [:new, :show] do
      resource :edit_session, only: [:update, :destroy], module: :attendances
    end
    resources :breaktimes, only: [:create, :update]
  end

  resource  :session, only: [:new, :create, :destroy]
end
