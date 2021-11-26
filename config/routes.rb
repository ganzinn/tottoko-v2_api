Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do

      resources :hello, only: [:index]

      resource :users, only: [:create] do
        post :pasword_reset_entry
        # resource :password_reset, only: [:create, :update]
        resource :me, controller: :me, only: [:show] do
          put :activate
          patch :activate
          put :password, to: 'me#password_reset'
          patch :password, to: 'me#password_reset'
        end
      end
      
      namespace :sessions do
        post :login
        post :refresh
        delete :logout
      end
    end
  end
end
