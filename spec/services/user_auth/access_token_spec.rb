require 'rails_helper'

RSpec.describe UserAuth::AccessToken, type: :model do
  
  before do
    @user = FactoryBot.build(:user)
    @user.activated = true
    @user.save
  end

  describe 'トークン検証' do
    context '共通メソッド' do
      before do
        @encode_token_instance = UserAuth::AccessToken.new(user_id: @user.id)
      end
      it 'アルゴリズムは「HS256」であること' do
        expect(@encode_token_instance.send(:algorithm)).to match("HS256")
      end
      it 'エンコードキーとデコードキーが同じであること' do
        expect(@encode_token_instance.send(:encode_key)).to match(@encode_token_instance.send(:decode_key))
      end
      it 'ユーザーを識別するクレーム（:user_claim）が「:sub」であること' do
        expect(@encode_token_instance.send(:user_claim)).to match(:sub)
      end
      it 'ヘッダーが「{ typ: "JWT", alg: "HS256" }」であること' do
        expect(@encode_token_instance.send(:header_fields)).to match({ typ: "JWT", alg: "HS256" })
      end
    end
    context 'トークン発行時（エンコード時）' do
      before do
        @encode_token_instance = UserAuth::AccessToken.new(user_id: @user.id)
        @payload = @encode_token_instance.payload
      end
      it '有効期限がデフォルト設定の時、payload[:exp]の値が30分後（誤差1秒以内）であること' do
        payload_exp = @payload[:exp]
        expect(payload_exp).to be_within(1).of(30.minute.from_now.to_i)
      end
      it '有効期限がデフォルト設定の時、lifetime_textメソッドは「30分」と出力すること' do
        expect(@encode_token_instance.lifetime_text).to match("30分")
      end
      it '有効期限を1時間に設定した時、payload[:exp]の値が1時間後（誤差1秒以内）であること' do
        @encode_token_instance = UserAuth::AccessToken.new(user_id: @user.id, payload: {lifetime: 1.hour})
        payload_exp = @payload[:exp]
        expect(payload_exp).to be_within(1).of(30.minute.from_now.to_i)
      end
      it '有効期限を1時間に設定した時、lifetime_textメソッドは「1時間」と出力すること' do
        @encode_token_instance = UserAuth::AccessToken.new(user_id: @user.id, payload: {lifetime: 1.hour})
        expect(@encode_token_instance.lifetime_text).to match("1時間")
      end
      it 'payload[:sub]の値がencode_user_idであること' do
        payload_sub = @payload[:sub]
        expect_encode_user_id = @encode_token_instance.encode_user_id
        expect(payload_sub).to match(expect_encode_user_id)
      end
      it 'payload[:iss]の値が環境変数"API_URL"の値であること' do
        payload_iss = @payload[:iss]
        expect(payload_iss).to match(ENV["API_URL"])
      end
      it 'payload[:aud]の値が環境変数"API_URL"の値であること' do
        payload_aud = @payload[:aud]
        expect(payload_aud).to match(ENV["API_URL"])
      end
    end
    context 'トークン検証時（デコード時）' do
      before do
        encode_token_instance = UserAuth::AccessToken.new(user_id: @user.id)
        @lifetime = encode_token_instance.lifetime
        @token = encode_token_instance.token
      end
      it 'トークンをデコードしたユーザーとエンコード時に設定したユーザが一致すること' do
        decode_token_instance = UserAuth::AccessToken.new(token: @token)
        decode_user = decode_token_instance.entity_for_user
        expect(decode_user).to match(@user)
      end
      it '有効期限内（期限1秒前）のトークンをデコードした時、例外を発生さないこと' do
        travel_to (@lifetime.from_now - 1.second) do
          expect{ UserAuth::AccessToken.new(token: @token) }
        end
      end
      it '有効期限を過ぎた直後にトークンをデコードした時、「JWT::ExpiredSignature」の例外を発生させ、messageが「Signature has expired」となること' do
        travel_to (@lifetime.from_now) do
          expect do
            UserAuth::AccessToken.new(token: @token)
          end.to raise_error(JWT::ExpiredSignature, "Signature has expired")
        end
      end
      it 'トークンが改竄（header部が変更）された場合、「JWT::DecodeError」を継承する例外が発生すること' do
        split_token = @token.split('.')
        invalid_header = Base64.urlsafe_encode64({
          typ: "aJWT",
          alg: "aHS256"
        }.to_json)
        split_token[0] = invalid_header
        invalid_token = split_token.join('.')
        expect do
          UserAuth::AccessToken.new(token: invalid_token)
        end.to raise_error(JWT::DecodeError)
      end
      it 'トークンが改竄（payload部が変更）された場合、「JWT::DecodeError」を継承する例外が発生すること' do
        split_token = @token.split('.')
        decode_payload = JSON.parse Base64.urlsafe_decode64(split_token[1])
        invalid_payload_iss = 'https://invalid.com'
        invalid_payload = decode_payload
        invalid_payload["iss"] = invalid_payload_iss
        encode_invalid_payload = Base64.urlsafe_encode64(invalid_payload.to_json)
        split_token[1] = encode_invalid_payload
        invalid_token = split_token.join('.')
        expect do
          UserAuth::AccessToken.new(token: invalid_token)
        end.to raise_error(JWT::DecodeError)
      end
      it 'トークンが改竄（payload部を変更し、それに合わせて別の鍵で署名部を作成し変更）された場合、「JWT::DecodeError」を継承する例外が発生すること' do
        split_token = @token.split('.')
        decode_header = JSON.parse Base64.urlsafe_decode64(split_token[0])
        decode_payload = JSON.parse Base64.urlsafe_decode64(split_token[1])
        invalid_payload_iss = 'https://invalid.com'
        invalid_payload = decode_payload
        invalid_payload["iss"] = invalid_payload_iss
        invalid_token = JWT.encode(invalid_payload, "dummy_key", decode_header["alg"], decode_header)
        expect do
          UserAuth::AccessToken.new(token: invalid_token)
        end.to raise_error(JWT::DecodeError)
      end
    end
  end
end
