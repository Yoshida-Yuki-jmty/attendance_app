# For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
Rails.application.routes.draw do
  root 'attendances#show'

  resources :users do
    resource  :current_attendance,  only: [:show, :create, :update], controller: "attendances"
    resources :attendances, only: [:index, :destroy],                controller: "attendances" do
      member do
        get   :edit_row
        patch :save_row
        get   :cancel_row
      end
      collection do
      post  :build_row
      end
    end
    resources :breaktimes,  only: [:create, :update]
  end

  resource  :session,     only: [:new, :create, :destroy]
end
