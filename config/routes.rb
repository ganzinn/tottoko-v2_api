Rails.application.routes.draw do
  namespace :api do
    resources :health_check, only: :index

    namespace :v1 do

      resource :users, only: [:create] do
        post :password_reset_entry

        resource :me, controller: :me, only: [:show] do
          put :activate
          put :password, to: 'me#password_reset'
          post :email_change_entry, to: 'me#email_change_entry'
          put :email, to: 'me#email_change'

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
