Rails.application.routes.draw do
  resources :sources, only: [:create]
  root 'application#default'
end
