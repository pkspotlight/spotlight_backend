Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  resources :list_videos, only: [] do
    get 'status', on: :collection
  end

  resources :video, only: [] do
    post 'upload', on: :collection
    get 'find', on: :collection
    get 'find_combined', on: :collection
  end

  resources :user, only: [] do
    get 'videos', on: :collection
  end
end
