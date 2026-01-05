Rails.application.routes.draw do
  resources :videos, only: [:create]
  resources :feeds, only: :show

  root 'application#default'
end
