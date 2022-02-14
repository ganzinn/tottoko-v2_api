Rails.application.routes.draw do
  namespace :api do
    resources :health_check, only: :index

    namespace :v1 do
      namespace :sessions do
        post :login
        post :refresh
        delete :logout
      end

      resource :users, only: [:create] do
        post :password_reset_entry

        resource :me, controller: :me, only: [:show] do
          put :activate
          put :password, to: 'me#password_reset'
          post :email_change_entry, to: 'me#email_change_entry'
          put :email, to: 'me#email_change'

          resources :creators, controller: :my_creators, only: [:create, :index]
          resources :works, controller: :my_works, only: [:index, :create]
        end
      end

      resources :creators, only: [:show, :update, :destroy] do
        resources :families, only: [:create, :destroy]
      end
      
      resources :works, only: [:show, :update, :destroy] do
        resources :comments, only: [:create, :index, :update, :destroy]
        resource :like, only: [:create, :destroy] do
          get :count
        end
      end
    end
  end
end
