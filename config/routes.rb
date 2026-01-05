Rails.application.routes.draw do
  resources :videos, only: [:create, :destroy]
  resources :feeds, only: :show

  root 'application#default'
end
