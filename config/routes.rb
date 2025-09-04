# For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
Rails.application.routes.draw do
  root 'sessions#new'
  resources :users
  resource  :session, only: %i[new create destroy]
end
