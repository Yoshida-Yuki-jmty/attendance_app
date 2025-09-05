# For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
Rails.application.routes.draw do
  root 'attendances#index'
  resources :users
  resource  :session, only: [:new, :create, :destroy]
  resources :attendances, except: [:new, :show, :destroy]
  resources :breaktimes,  only: [:create, :update]
end
