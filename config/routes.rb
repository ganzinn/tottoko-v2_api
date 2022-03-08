Rails.application.routes.draw do
  namespace :api do
    resources :health_check, only: :index

    namespace :v1 do
      resource :users, only: [:create] do
        post :password_reset_entry

        resource :sessions, controller: :sessions, only: [] do
          post :login
          post :refresh
          delete :logout
        end

        resource :me, controller: :me, only: [:show, :update] do
          put :activate
          put :password, to: 'me#password_reset'
          post :email_change_entry
          put :email, to: 'me#email_change'

          resources :creators, controller: :my_creators, only: [:create, :index]
          resources :works, controller: :my_works, only: [:index, :create]
        end
      end

      resources :creators, only: [:show, :update, :destroy] do
        resources :families, only: [:create, :destroy]
      end
      
      resources :works, only: [:show, :update, :destroy] do
        resources :comments, controller: :work_comments, only: [:create, :index]
        resource :like, only: [:create, :destroy] do
          get :count
        end
      end

      resources :comments, only: [:update, :destroy]

      # 選択フィールド
      resources :genders, only:[:index]
      resources :relations, only:[:index]
      resources :scopes, only:[:index]

    end
  end
end
