# For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
Rails.application.routes.draw do
  root 'current_attendances#show'

  resources :users do
    resource  :current_attendance, only: [:show, :create, :update]
    resources :attendances, except: [:new] do
      resource :edit_session, only: [:destroy], module: :attendances
    end
    resources :breaktimes, only: [:create, :update]
  end

  resource  :session, only: [:new, :create, :destroy]
end
