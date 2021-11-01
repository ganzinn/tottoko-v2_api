require 'rails_helper'

RSpec.describe UserAuth::RefreshToken, type: :model do
  
  before do
    @user = FactoryBot.build(:user)
    @user.activated = true
    @user.save
    @encode_token_instance = UserAuth::RefreshToken.new(user_id: @user.id)
    # 有効期限の誤差を小さくするため、tokenエンコード直後に算出
    @lifetime = UserAuth.refresh_token_lifetime
  end

  describe 'トークン検証' do
    context 'エンコード時' do
      before do
        @encode_payload = @encode_token_instance.payload
      end
      it 'payload[:exp]の値が算出した期限との誤差1秒以内であること' do
        expect_lifetime = @lifetime.from_now.to_i
        payload_exp = @encode_payload[:exp]
        expect(payload_exp).to be_within(1).of(expect_lifetime)
      end
      it 'payload[:jti]の値がユーザーテーブルに格納したrefresh_jtiと同じであること' do
        # user = @encode_token_instance.entity_for_user
        # expect_jti = user.refresh_jti
        @user.reload
        expect_jti = @user.refresh_jti
        payload_jti = @encode_payload[:jti]
        expect(payload_jti).to match(expect_jti)
      end
      it 'payload[:sub]の値がトークンのインスタンス変数user_idと同じであること' do
        payload_sub = @encode_payload[:sub]
        encode_user_id = @encode_token_instance.encode_user_id
        expect(payload_sub).to match(encode_user_id)
      end
    end
    context 'デコード時' do
      before do
        @decode_token_instance = UserAuth::RefreshToken.new(token: @encode_token_instance.token)
        @user.reload
      end
      it 'トークンからユーザーを特定できること' do
        token_user = @decode_token_instance.entity_for_user
        expect(token_user).to match(@user)
      end
      it '有効期限切れのトークンの場合、例外(JWT::ExpiredSignature)を発生させ、messageが「Signature has expired」となること' do
        travel_to (@lifetime.from_now) do
          expect do
            UserAuth::RefreshToken.new(token: @encode_token_instance.token)
          end.to raise_error(JWT::ExpiredSignature, "Signature has expired")
        end
      end
      it 'トークンが書き換えられた場合、例外（JWT::VerificationError）が発生し、messageが「Signature verification raised」となること' do
        invalid_token = @encode_token_instance.token + "invalid"
        expect do
          UserAuth::RefreshToken.new(token: invalid_token)
        end.to raise_error(JWT::VerificationError, "Signature verification raised")
      end
      it 'テーブルに格納されているrefresh_jtiが異なる場合、例外（JWT::InvalidJtiError）が発生し、messageが「InvalidJtiError」となること' do
        @user.remember("invalid")
        expect do
          UserAuth::RefreshToken.new(token: @encode_token_instance.token)
        end.to raise_error(JWT::InvalidJtiError, "Invalid jti")
      end
      it 'テーブルにrefresh_jtiが格納されていない場合、例外（JWT::InvalidJtiError）が発生し、messageが「InvalidJtiError」となること' do
        @user.forget
        expect do
          UserAuth::RefreshToken.new(token: @encode_token_instance.token)
        end.to raise_error(JWT::InvalidJtiError, "Invalid jti")
      end
    end
  end
end
