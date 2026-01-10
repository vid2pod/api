Rails.application.routes.draw do
  resources :feeds, only: :show
  resources :videos, only: [:create, :destroy] do
    member do
      get :audio
    end
  end

  root 'application#default'
end
