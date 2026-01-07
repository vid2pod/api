Rails.application.routes.draw do
  resources :feeds, only: :show do
    resources :videos, only: [:create, :destroy]
  end

  root 'application#default'
end
