Rails.application.routes.draw do
  resources :feeds, only: :show
  resources :videos, only: [:create, :destroy]

  root 'application#default'
end
