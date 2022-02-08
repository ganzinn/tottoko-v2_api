require 'rails_helper'

RSpec.describe "Api::V1::Sessions", type: :request do

  #################################################
  ### ログイン
  #################################################
  describe "ログイン 'POST /api/v1/sessions/login'" do
    before do
      @user = FactoryBot.build(:user)
      @user.activated = true
      @user.save
    end
    context 'パラメータが妥当な場合' do
      it 'レスポンスが正常（アクセストークン・リフレッシュトークンの付与）であること' do
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
        end
      end
    end
    context 'パラメータが不正な場合' do
      it '【パスワード相違】エラーレスポンスの返答かつ、リフレッシュトークンが付与されていないこと' do
        headers = {
          'Content-Type': 'application/json'
        }
        json_params = ({
          "auth": {
            "email": "aaa@abc.com",
            "password": "password_bbbb" # password相違
          }
        }).to_json
        post '/api/v1/sessions/login', headers: headers, params: json_params
        body_hash = JSON.parse(response.body)
        aggregate_failures do
          # エラーレスポンス
          expect(response.status).to eq 401
          expect(body_hash["success"]).to eq false
          expect(body_hash["code"]).to eq "authenticate_fail"
          expect(body_hash["messages"]["base"]).to match(["認証に失敗しました"])
          # リフレッシュトークンが付与されていないかチェック
          expect(cookies).to_not include("refresh_token")
        end
      end
      it '【メルアド相違】エラーレスポンスの返答かつ、リフレッシュトークンが付与されていないこと' do
        headers = {
          'Content-Type': 'application/json'
        }
        json_params = ({
          "auth": {
            "email": "aaa@abc.com_bbbb", # メルアド相違
            "password": "password"
          }
        }).to_json
        post '/api/v1/sessions/login', headers: headers, params: json_params
        body_hash = JSON.parse(response.body)
        aggregate_failures do
          # エラーレスポンス
          expect(response.status).to eq 401
          expect(body_hash["success"]).to eq false
          expect(body_hash["code"]).to eq "authenticate_fail"
          expect(body_hash["messages"]["base"]).to match(["認証に失敗しました"])
          # リフレッシュトークンが付与されていないかチェック
          expect(cookies).to_not include("refresh_token")
        end
      end
    end
  end

  #################################################
  ### トークンリフレッシュ
  #################################################
  describe "トークンリフレッシュ 'POST /api/v1/sessions/refresh'" do
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
      @refresh_token = cookies["refresh_token"]
      @before_refresh_jti = User.find(@user.id).refresh_jti
    end
    context 'リフレッシュトークンが妥当な場合' do
      it 'レスポンスが正常（アクセストークン・リフレッシュトークンの付与）かつ、「refresh_jti」が更新されること' do
        headers = {
          'Cookie': "refresh_token=#{@refresh_token}"
        }
        post '/api/v1/sessions/refresh', headers: headers
        body_hash = JSON.parse(response.body)
        aggregate_failures do
          # レスポンスチェック
          expect(response.status).to eq 200
          expect(body_hash["success"]).to eq true
          expect(body_hash).to include("token")
          expect(body_hash).to include("expires")
          expect(body_hash).to include("user")
          # リフレッシュトークン存在チェック
          expect(cookies["refresh_token"]).not_to be_empty
          # refresh_jtiの更新チェック
          after_refresh_jti = User.find(@user.id).refresh_jti
          expect(after_refresh_jti).not_to eq @before_refresh_jti

        end
      end
    end
    context 'リフレッシュトークンが不正な場合' do
      it '【トークン期限切れ[24時間後]】リフレッシュトークンが付与されていないこと、および「refresh_jti」が更新されないこと' do
        headers = {
          'Cookie': "refresh_token=#{@refresh_token}"
        }
        travel_to (24.hour.from_now) do
          post '/api/v1/sessions/refresh', headers: headers
          body_hash = JSON.parse(response.body)
          aggregate_failures do
            # レスポンスチェック
            expect(response.status).to eq 401
            expect(body_hash["success"]).to eq false
            expect(body_hash["code"]).to eq "refresh_token_expired"
            expect(body_hash["messages"]["base"]).to match(["RefreshToken の有効期限切れです"])
            # リフレッシュトークンが空となっているかチェック
            expect(cookies["refresh_token"]).to be_empty
            # refresh_jtiの更新チェック
            after_refresh_jti = User.find(@user.id).refresh_jti
            expect(after_refresh_jti).to eq @before_refresh_jti
          end
        end
      end
    end
  end

  #################################################
  ### ログアウト
  #################################################
  describe "ログアウト 'DELETE /api/v1/sessions/logout'" do
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
      @refresh_token = cookies["refresh_token"]
      @before_refresh_jti = User.find(@user.id).refresh_jti
    end
    context 'リフレッシュトークンが妥当な場合' do
      it 'レスポンスが正常かつ、リフレッシュトークンが空であること' do
        headers = {
          'Cookie': "refresh_token=#{@refresh_token}"
        }
        delete '/api/v1/sessions/logout', headers: headers
        body_hash = JSON.parse(response.body)
        aggregate_failures do
          # レスポンスチェック
          expect(response.status).to eq 200
          expect(body_hash["success"]).to eq true
          # リフレッシュトークン存在チェック
          expect(cookies["refresh_token"]).to be_empty
          # refresh_jtiの削除チェック
          after_refresh_jti = User.find(@user.id).refresh_jti
          expect(after_refresh_jti).to eq nil
        end
      end
    end
    context 'リフレッシュトークンが不正な場合' do
      it '【トークン期限切れ[24時間後]】エラーレスポンスの返答かつ、リフレッシュトークンが空であること' do
        headers = {
          'Cookie': "refresh_token=#{@refresh_token}"
        }
        travel_to (24.hour.from_now) do
          post '/api/v1/sessions/refresh', headers: headers
          body_hash = JSON.parse(response.body)
          aggregate_failures do
            # レスポンスチェック
            expect(response.status).to eq 401
            expect(body_hash["success"]).to eq false
            expect(body_hash["code"]).to eq "refresh_token_expired"
            expect(body_hash["messages"]["base"]).to match(["RefreshToken の有効期限切れです"])
            # リフレッシュトークンが空となっているかチェック
            expect(cookies["refresh_token"]).to be_empty
            # refresh_jtiが削除されていないかチェック（前回と同じrefresh_jti）
            after_refresh_jti = User.find(@user.id).refresh_jti
            expect(after_refresh_jti).to eq @before_refresh_jti
          end
        end
      end
    end
  end
end