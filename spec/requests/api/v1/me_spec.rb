require 'rails_helper'

RSpec.describe "Api::V1::Me", type: :request do
  
  #################################################
  ### アカウント アクティベイト
  #################################################
  describe "アカウント アクティベイト 'PUT /api/v1/users/me/activate'" do
    before do
      @user = FactoryBot.build(:user)
      @user.save
      @activate_token = UserAuth::ActivateToken.encode(@user.id).token
    end
    context 'アクティベイトトークンが妥当な場合' do
      it 'レスポンスが正常（アクセストークン・リフレッシュトークンの付与）かつ、ユーザーアクティブ化であること' do
        headers = {
          'Authorization': "Bearer #{@activate_token}"
        }
        put '/api/v1/users/me/activate', headers: headers
        body_hash = JSON.parse(response.body)
        aggregate_failures do
          # レスポンスチェック
          expect(response.status).to eq 200
          expect(body_hash["success"]).to eq true
          expect(body_hash).to include("token")
          expect(body_hash).to include("expires")
          expect(body_hash).to include("user")
          # リフレッシュトークン存在チェック
          expect(cookies).to include("refresh_token")
          # 登録ユーザアクティブ化チェック
          expect( User.find(@user.id).activated ).to eq true
        end
      end
    end
    context 'アクティベイトトークンが不正な場合' do
      it '【トークン期限切れ[1時間後]】エラーレスポンスかつ、登録ユーザーがアクティブしていないこと' do
        headers = {
          'Authorization': "Bearer #{@activate_token}"
        }
        travel_to (1.hour.from_now) do
          put '/api/v1/users/me/activate', headers: headers
          body_hash = JSON.parse(response.body)
          aggregate_failures do
            expect(response.status).to eq 401
            expect(body_hash["success"]).to eq false
            expect(body_hash["code"]).to eq "activate_token_expired"
            expect(body_hash["messages"]["base"]).to match(["ActivateToken の有効期限切れです"])
            # 登録ユーザがアクティブ化していないかチェック
            expect( User.find(@user.id).activated ).to eq false
          end
        end
      end
    end
  end

  #################################################
  ### ユーザー情報詳細 参照
  #################################################
  describe "ユーザー情報詳細 参照 'GET /api/v1/users/me'" do
    before do
      @user = FactoryBot.build(:user)
      @user.activated = true
      @user.save
      # ログイン
      headers = {
        'Content-Type': 'application/json'
      }
      json_params = ({
        "auth": {
          "email": "aaa@abc.com",
          "password": "password"
        }
      }).to_json
      post '/api/v1/sessions/login', headers: headers, params: json_params
      @access_token = JSON.parse(response.body)["token"]
    end
    context 'アクセストークンが妥当な場合' do
      it 'レスポンスが正常かつ、リフレッシュトークンが空であること' do
        headers = {
          'Authorization': "Bearer #{@access_token}"
        }
        get '/api/v1/users/me', headers: headers
        body_hash = JSON.parse(response.body)
        aggregate_failures do
          # レスポンスチェック
          expect(response.status).to eq 200
          expect(body_hash["success"]).to eq true
          # ユーザー詳細情報 存在チェック
          expect(body_hash).to include("user")
        end
      end
    end
    context 'アクセストークンが不正な場合' do
      it '【トークン期限切れ[30分後]】エラーレスポンスが返答されること' do
        headers = {
          'Authorization': "Bearer #{@access_token}"
        }
        travel_to (30.minute.from_now) do
          get '/api/v1/users/me', headers: headers
          body_hash = JSON.parse(response.body)
          aggregate_failures do
            # レスポンスチェック
            expect(response.status).to eq 401
            expect(body_hash["success"]).to eq false
            expect(body_hash["code"]).to eq "access_token_expired"
            expect(body_hash["messages"]["base"]).to match(["AccessToken の有効期限切れです"])
            # ユーザー詳細情報 存在チェック(含まれていないこと)
            expect(body_hash).not_to include("user")
          end
        end
      end
    end
  end

  #################################################
  ### パスワード リセット
  #################################################
  describe "パスワード リセット 'PUT /api/v1/users/me/password'" do
    before do
      @user = FactoryBot.build(:user)
      @user.activated = true
      @user.save
      @password_reset_token = UserAuth::PasswordResetToken.encode(@user.id).token
    end
    context 'パラメーターが妥当な場合' do
      it '正常レスポンスが返答されること' do
        headers = {
          'Authorization': "Bearer #{@password_reset_token}",
          'Content-Type': 'application/json'
        }
        json_params = ({
          "user": {
            "password": "changed_password",
            "password_confirmation": "changed_password"
          }
        }).to_json
        put '/api/v1/users/me/password', headers: headers, params: json_params
        body_hash = JSON.parse(response.body)
        aggregate_failures do
          # レスポンスチェック
          expect(response.status).to eq 200
          expect(body_hash["success"]).to eq true
        end
      end
    end
    context 'パラメーターが不正な場合' do
      it '【「パスワード確認」が「パスワード」と相違】エラーレスポンスが返答されること' do
        headers = {
          'Authorization': "Bearer #{@password_reset_token}",
          'Content-Type': 'application/json'
        }
        json_params = ({
          "user": {
            "password": "changed_password",
            "password_confirmation": "changed_password_bbbb" # パスワード相違
          }
        }).to_json
        put '/api/v1/users/me/password', headers: headers, params: json_params
        body_hash = JSON.parse(response.body)
        aggregate_failures do
          # レスポンスチェック
          expect(response.status).to eq 422
          expect(body_hash["success"]).to eq false
          body_hash["messages"].each{ |attr, messages|
            messages.each{ |message|
              expect(message).to be_kind_of(String)
            }
          }
        end
      end
      it '【トークン期限切れ[30分後]】エラーレスポンスが返答されること' do
        headers = {
          'Authorization': "Bearer #{@password_reset_token}",
          'Content-Type': 'application/json'
        }
        json_params = ({
          "user": {
            "password": "changed_password",
            "password_confirmation": "changed_password"
          }
        }).to_json
        travel_to (30.minute.from_now) do
          put '/api/v1/users/me/password', headers: headers, params: json_params
          body_hash = JSON.parse(response.body)
          aggregate_failures do
            expect(response.status).to eq 401
            expect(body_hash["success"]).to eq false
            expect(body_hash["code"]).to eq "password_reset_token_expired"
            expect(body_hash["messages"]["base"]).to match(["PasswordResetToken の有効期限切れです"])
          end
        end
      end
    end
  end

  #################################################
  ### メールアドレス変更 エントリー
  #################################################
  describe "メールアドレス変更 エントリー 'POST /api/v1/users/me/email_change_entry'" do
    before do
      @user = FactoryBot.build(:user)
      @user.activated = true
      @user.save
      # ログイン
      headers = {
        'Content-Type': 'application/json'
      }
      json_params = ({
        "auth": {
          "email": "aaa@abc.com",
          "password": "password"
        }
      }).to_json
      post '/api/v1/sessions/login', headers: headers, params: json_params
      @access_token = JSON.parse(response.body)["token"]
    end
    context 'パラメーターが妥当な場合' do
      it '正常レスポンスが返答されること' do
        headers = {
          'Authorization': "Bearer #{@access_token}",
          'Content-Type': 'application/json'
        }
        json_params = ({
          "user": {
            "email": "aaa_change@abc.com"
          }
        }).to_json
        post '/api/v1/users/me/email_change_entry', headers: headers, params: json_params
        body_hash = JSON.parse(response.body)
        aggregate_failures do
          # レスポンスチェック
          expect(response.status).to eq 200
          expect(body_hash["success"]).to eq true
        end
      end
    end
    context 'パラメーターが不正な場合' do
      it 'エラーレスポンスが返答されること' do
        #別ユーザー登録
        other_user = FactoryBot.build(:user)
        other_user.email = "another@abc.com"
        other_user.activated = true
        other_user.save

        headers = {
          'Authorization': "Bearer #{@access_token}",
          'Content-Type': 'application/json'
        }
        json_params = ({
          "user": {
            "email": other_user.email # 別ユーザーのメルアド指定
          }
        }).to_json
        post '/api/v1/users/me/email_change_entry', headers: headers, params: json_params
        body_hash = JSON.parse(response.body)
        aggregate_failures do
          # レスポンスチェック
          expect(response.status).to eq 422
          expect(body_hash["success"]).to eq false
          body_hash["messages"].each{ |attr, messages|
            messages.each{ |message|
              expect(message).to be_kind_of(String)
            }
          }
        end
      end
    end
  end

  #################################################
  ### メールアドレス変更
  #################################################
  describe "メールアドレス変更 'PUT /api/v1/users/me/email'" do
    before do
      @user = FactoryBot.build(:user)
      @user.activated = true
      @user.save
      # メルアド変更 エントリー
      @changed_email = "changed_email@abc.com"
      @email_change_token = UserAuth::EmailChangeToken.encode(@user.id, @changed_email).token
    end
    context 'Eメール変更トークンとパラメーター（パスワード）が妥当な場合' do
      it '正常レスポンスが返答されること かつ、変更対象メルアドが反映されていること' do
        headers = {
          'Authorization': "Bearer #{@email_change_token}",
          'Content-Type': 'application/json'
        }
        json_params = ({
          "user": {
            "password": 'password'
          }
        }).to_json
        put '/api/v1/users/me/email', headers: headers, params: json_params
        body_hash = JSON.parse(response.body)
        aggregate_failures do
          # レスポンスチェック
          expect(response.status).to eq 200
          expect(body_hash["success"]).to eq true
          expect(body_hash).to include("token")
          expect(body_hash).to include("expires")
          expect(body_hash).to include("user")
          # リフレッシュトークン存在チェック
          expect(cookies).to include("refresh_token")
          # 変更対象メルアドが反映されていること
          expect(User.find(@user.id).email).to eq @changed_email
        end
      end
    end
    context 'パラメーターが不正な場合' do
      it '【パスワード相違】エラーレスポンスが返答されること かつ、変更対象メルアドが反映されていないこと' do
        headers = {
          'Authorization': "Bearer #{@email_change_token}",
          'Content-Type': 'application/json'
        }
        json_params = ({
          "user": {
            "password": 'wrong_password' # 不正パスワード
          }
        }).to_json
        put '/api/v1/users/me/email', headers: headers, params: json_params
        body_hash = JSON.parse(response.body)
        aggregate_failures do
          # レスポンスチェック
          expect(response.status).to eq 401
          expect(body_hash["success"]).to eq false
          expect(body_hash["code"]).to eq "password_error"
          expect(body_hash["messages"]).to include("パスワードが相違しています")
          # 変更対象メルアドが反映されていないこと
          expect(User.find(@user.id).email).to eq @user.email
        end
      end
      it '【変更メルアド不正（既に存在）】エラーレスポンスが返答されること かつ、変更対象メルアドが反映されていないこと' do
        # 変更予定のメルアドで別ユーザーが新規登録
        other_user = FactoryBot.build(:user)
        other_user.email = @changed_email
        other_user.activated = true
        other_user.save

        headers = {
          'Authorization': "Bearer #{@email_change_token}",
          'Content-Type': 'application/json'
        }
        json_params = ({
          "user": {
            "password": 'password'
          }
        }).to_json
        put '/api/v1/users/me/email', headers: headers, params: json_params
        body_hash = JSON.parse(response.body)
        aggregate_failures do
          # レスポンスチェック
          expect(response.status).to eq 422
          expect(body_hash["success"]).to eq false
          expect(body_hash["code"]).to eq "unprocessable"
          expect(body_hash["messages"]["email"]).to match(["すでに存在します"])
          # 変更対象メルアドが反映されていないこと
          expect(User.find(@user.id).email).to eq @user.email
        end
      end
    end
    context 'Eメール変更トークンが不正な場合' do
      it '【トークン期限切れ[30分後]】エラーレスポンスが返答されること かつ、変更対象メルアドが反映されていないこと' do
        headers = {
          'Authorization': "Bearer #{@email_change_token}",
          'Content-Type': 'application/json'
        }
        json_params = ({
          "user": {
            "password": 'password'
          }
        }).to_json
        travel_to (30.minute.from_now) do
          put '/api/v1/users/me/email', headers: headers, params: json_params
          body_hash = JSON.parse(response.body)
          aggregate_failures do
            expect(response.status).to eq 401
            expect(body_hash["success"]).to eq false
            expect(body_hash["code"]).to eq "email_change_token_expired"
            expect(body_hash["messages"]["base"]).to match(["EmailChangeToken の有効期限切れです"])
            # 変更対象メルアドが反映されていないこと
            expect(User.find(@user.id).email).to eq @user.email
          end
        end
      end
    end
  end
end
