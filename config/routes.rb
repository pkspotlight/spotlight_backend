Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  resources :list_videos, only: [] do    
    get 'status', on: :collection
  end
end
