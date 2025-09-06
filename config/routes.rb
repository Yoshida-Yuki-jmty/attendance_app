# For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
Rails.application.routes.draw do
  root 'attendances#show'

  resources :users do
    resource  :attendance,  only: [:show, :create, :update], controller: "attendances"
    resources :attendances, only: [:index],                  controller: "attendances"
    resources :breaktimes,  only: [:create, :update],         controller: "breaktimes"
  end

  resource  :session,     only: [:new, :create, :destroy]
end
