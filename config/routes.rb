Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # api test action
      resources :hello, only: [:index]
      # users_controller
      resources :users, only: [:index]
      
      namespace :auth do
        post :login
        post :refresh
        delete :logout
      end
    end
  end
end
