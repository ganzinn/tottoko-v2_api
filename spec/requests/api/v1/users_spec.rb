require 'rails_helper'

RSpec.describe "Api::V1::Users", type: :request do

  #################################################
  ### 新規ユーザー登録
  #################################################
  describe "新規ユーザ登録 'POST /api/v1/users'" do
    context 'パラメータが妥当な場合' do
      it 'レスポンスが正常（status:201, success: true）であること' do
        headers = {
          'Content-Type': 'application/json'
        }
        json_params = {
          "user": {
            "name": "山田太郎",
            "email": "a@a.a",
            "password": "aaaaaaaa",
            "password_confirmation": "aaaaaaaa"
          }
        }.to_json
        post '/api/v1/users', headers: headers, params: json_params
        body_hash = JSON.parse(response.body)
        aggregate_failures do
          expect(response.status).to eq 201
          expect(body_hash["success"]).to eq true
        end
      end
      it 'Usersレコードが１件追加され、activated属性が「false」であること' do
        aggregate_failures do
          expect{ 
            post '/api/v1/users', params: {
              "user": {
                "name": "山田太郎",
                "email": "a@a.a",
                "password": "aaaaaaaa",
                "password_confirmation": "aaaaaaaa"
              }
            }
          }.to change{ User.count }.by(1)
          expect( User.last.activated ).to eq false
        end
      end
    end
    context 'パラメータが不正な場合' do
      it 'エラーレスポンス（status:422, success: false, messages: [ <文字列>(1個以上) ]）を返すこと' do
        headers = {
          'Content-Type': 'application/json'
        }
        json_params = {
          "user": {
            "name": "山田太郎",
            "email": "a@", # emailの書式が不正
            "password": "aaaaaaaa",
            "password_confirmation": "aaaaaaaabbb" # passwordと相違
          }
        }.to_json
        post '/api/v1/users', headers: headers, params: json_params
        body_hash = JSON.parse(response.body)
        aggregate_failures do
          expect(response.status).to eq 422
          expect(body_hash["success"]).to eq false
          expect(body_hash["messages"].size).to be >= 1
          body_hash["messages"].each{ |message|
            expect(message).to be_kind_of(String)
          }
        end
      end
    end
  end

  #################################################
  ### パスワード リセット エントリー
  #################################################
  describe "パスワード リセット エントリー 'POST /api/v1/users/password_reset_entry'" do
    context 'パラメータが妥当な場合' do
      it 'レスポンスが正常（status:200, success: true）であること' do
        headers = {
          'Content-Type': 'application/json'
        }
        json_params = {
          "user": {
            "email": "aaa@abc.com"
          }
        }.to_json
        post '/api/v1/users/password_reset_entry', headers: headers, params: json_params
        body_hash = JSON.parse(response.body)
        aggregate_failures do
          expect(response.status).to eq 200
          expect(body_hash["success"]).to eq true
        end
      end
    end
    context 'パラメータが不正な場合' do
      it 'レスポンスが正常（status:200, success: true）であること（※ セキュリティ観点から存在しないメルアドであっても正常レスポンスとする）' do
        headers = {
          'Content-Type': 'application/json'
        }
        json_params = {
          "user": {
            "email": "aaa@" # 存在しないメールアドレス
          }
        }.to_json
        post '/api/v1/users/password_reset_entry', headers: headers, params: json_params
        body_hash = JSON.parse(response.body)
        aggregate_failures do
          expect(response.status).to eq 200
          expect(body_hash["success"]).to eq true
        end
      end
    end
  end
end
