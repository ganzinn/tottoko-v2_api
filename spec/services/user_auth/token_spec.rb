require 'rails_helper'

RSpec.describe 'トークン検証', type: :model do
  
  before do
    @user = FactoryBot.build(:user)
    @user.activated = true
    @user.save
  end
  context 'トークン共通' do
    before do
      encode_token_ins = UserAuth::AccessToken.encode(@user.id)
      @lifetime = encode_token_ins.lifetime
      @token = encode_token_ins.token
    end
    it 'デコードしたトークンのユーザーがトークン生成時に設定したユーザと一致すること' do
      decode_token_ins = UserAuth::AccessToken.decode(@token)
      decode_user = decode_token_ins.user
      expect(decode_user).to match(@user)
    end
    it '有効期限内（期限1秒前）のトークンの場合、デコード時に例外が発生しないこと' do
      travel_to (@lifetime.from_now - 1.second) do
        expect{ UserAuth::AccessToken.decode(@token) }.not_to raise_error
      end
    end
    it '有効期限を過ぎたトークンの場合、デコード時に例外「JWT::ExpiredSignature」が発生し、messageが「Signature has expired」となること' do
      travel_to (@lifetime.from_now) do
        expect do
          UserAuth::AccessToken.decode(@token)
        end.to raise_error(JWT::ExpiredSignature, "Signature has expired")
      end
    end
    it 'トークン生成時のユーザがUsersテーブルから削除されていた場合、デコード時に例外「UserAuth::UserNotFoundError」が発生し、messageが「User not Found. Received user_id <user_id>」となること' do
      @user.destroy
      expect do
        UserAuth::AccessToken.decode(@token)
      end.to raise_error(UserAuth::UserNotFoundError, "User not Found. Received user_id " + @user.id.to_s)
    end
    it 'トークンが改竄（header部が変更）された場合、デコード時に例外「JWT::VerificationError」が発生し、messageが「Signature verification raised」となること' do
      split_token = @token.split('.')
      invalid_header = Base64.urlsafe_encode64({
        typ: "aJWT",
        alg: "aHS256"
      }.to_json)
      split_token[0] = invalid_header
      invalid_token = split_token.join('.')
      expect do
        UserAuth::AccessToken.decode(invalid_token)
      end.to raise_error(JWT::IncorrectAlgorithm, "Expected a different algorithm")
    end
    it 'トークンが改竄（payload部が変更）された場合、デコード時に例外「JWT::VerificationError」が発生し、messageが「Signature verification raised」となること' do
      split_token = @token.split('.')
      decode_payload = JSON.parse Base64.urlsafe_decode64(split_token[1])
      invalid_payload_sub = "10"
      invalid_payload = decode_payload
      invalid_payload["sub"] = invalid_payload_sub
      encode_invalid_payload = Base64.urlsafe_encode64(invalid_payload.to_json)
      split_token[1] = encode_invalid_payload
      invalid_token = split_token.join('.')
      expect do
        UserAuth::AccessToken.decode(invalid_token)
      end.to raise_error(JWT::VerificationError, "Signature verification raised")
    end
    it '異なる鍵で再生成されたトークン（header, payloadの内容は同じ）の場合、デコード時に例外「JWT::VerificationError」が発生し、messageが「Signature verification raised」となること' do
      split_token = @token.split('.')
      decode_header = JSON.parse Base64.urlsafe_decode64(split_token[0])
      decode_payload = JSON.parse Base64.urlsafe_decode64(split_token[1])
      other_key_token = JWT.encode(decode_payload, "other_key", decode_header["alg"], decode_header)
      expect do
        UserAuth::AccessToken.decode(other_key_token)
      end.to raise_error(JWT::VerificationError, "Signature verification raised")
    end
    it 'トークンの署名アルゴリズムが「"HS256"」でない場合、デコード時に例外「JWT::IncorrectAlgorithm」が発生し、messageが「Expected a different algorithm」となること' do
      split_token = @token.split('.')
      decode_header = JSON.parse Base64.urlsafe_decode64(split_token[0])
      decode_payload = JSON.parse Base64.urlsafe_decode64(split_token[1])
      decode_header["alg"] = "RS256"
      # rsa_public = Rails.application.credentials.secret_key_base.public_key
      rsa_private = OpenSSL::PKey::RSA.generate(2048)
      rsa_public  = rsa_private.public_key
      other_alg_token = JWT.encode(decode_payload, rsa_private, decode_header["alg"], decode_header)
      expect do
        UserAuth::AccessToken.decode(other_alg_token)
      end.to raise_error(JWT::IncorrectAlgorithm, "Expected a different algorithm")
    end
    it '必須クレームが設定されていない（typクレームがない）トークンの場合、デコード時に例外「JWT::MissingRequiredClaim」が発生し、messageが「Missing required claim <クレーム名>」となること' do
      token = UserAuth::EncodeToken.new(@user.id, {}, nil).token
      expect do
        UserAuth::AccessToken.decode(token)
      end.to raise_error(JWT::MissingRequiredClaim, "Missing required claim typ")
    end
  end
  context 'AccessToken' do
    before do
      encode_token_ins = UserAuth::AccessToken.encode(@user.id)
      @lifetime = encode_token_ins.lifetime
      @token = encode_token_ins.token
    end
    it '有効期限が30分であること' do
      expect(@lifetime).to match(30.minute)
    end
    it 'typクレームが「access」でない場合、デコード時に例外「UserAuth::InvalidTypError」が発生し、messageが「Invalid type. Expected access, received <受け取ったトークンのtype名>」となること' do
      other_type_token = UserAuth::RefreshToken.encode(@user.id).token
      expect do
        UserAuth::AccessToken.decode(other_type_token)
      end.to raise_error(UserAuth::InvalidTypError, "Invalid type. Expected access, received refresh")
    end
  end
  context 'RefreshToken' do
    before do
      @encode_token_ins = UserAuth::RefreshToken.encode(@user.id)
      @lifetime = @encode_token_ins.lifetime
      @user.remember_jti!(@encode_token_ins.payload[:jti])
    end
    it '有効期限が1日であること' do
      expect(@lifetime).to match(1.day)
    end
    it '「jti」クレームがないトークンの場合、デコード時に例外「JWT::MissingRequiredClaim」が発生し、messageが「Missing required claim jti」となること' do
      no_jti_claim_token = UserAuth::AccessToken.encode(@user.id).token
      expect do
        UserAuth::RefreshToken.decode(no_jti_claim_token)
      end.to raise_error(JWT::MissingRequiredClaim, "Missing required claim jti")
    end
    it 'typクレームが「refresh」でない場合、デコード時に例外「UserAuth::InvalidTypError」が発生し、messageが「Invalid type. Expected access, received <受け取ったトークンのtype名>」となること' do
      token_base_ins = UserAuth::TokenBase.new(:aaa)
      add_payload = {
        jti: Digest::MD5.hexdigest(SecureRandom.uuid)
      }
      other_type_token = token_base_ins.encode(@user.id, add_payload: add_payload).token
      
      expect do
        UserAuth::RefreshToken.decode(other_type_token)
      end.to raise_error(UserAuth::InvalidTypError, "Invalid type. Expected refresh, received aaa")
    end
    it 'トークンのjtiがUsersテーブルのrefresh_jtiと同じ場合、デコード時に例外が発生しないこと' do
      expect do
        UserAuth::RefreshToken.decode(@encode_token_ins.token)
      end.not_to raise_error
    end
    it 'トークンのjtiがUsersテーブルのrefresh_jtiと異なる場合、デコード時に例外「UserAuth::InvalidJtiError」が発生し、messageが「Invalid refresh_jti. Received <トークンのjti> not included session」となること' do
      @user.remember_jti!("invalid")
      expect do
        UserAuth::RefreshToken.decode(@encode_token_ins.token)
      end.to raise_error(UserAuth::InvalidJtiError, "Invalid refresh_jti. Received #{@encode_token_ins.payload[:jti] } not included session")
    end
  end
  context 'ActivateToken' do
    before do
      @encode_token_ins = UserAuth::ActivateToken.encode(@user.id)
      @lifetime = @encode_token_ins.lifetime
    end
    it '有効期限が1日であること' do
      expect(@lifetime).to match(1.hour)
    end
    it 'typクレームが「activate」でない場合、デコード時に例外「UserAuth::InvalidTypError」が発生し、messageが「Invalid type. Expected access, received <受け取ったトークンのtype名>」となること' do
      other_type_token = UserAuth::RefreshToken.encode(@user.id).token
      expect do
        UserAuth::ActivateToken.decode(other_type_token)
      end.to raise_error(UserAuth::InvalidTypError, "Invalid type. Expected activate, received refresh")
    end
    it 'トークンのユーザーがactivateしていない(activated == false)場合、デコード時に例外が発生しないこと' do
      @user.update!(activated: false)
      expect do
        UserAuth::ActivateToken.decode(@encode_token_ins.token)
      end.not_to raise_error
    end
    it 'トークンのユーザーが既にactivateしている(activated == true)場合、デコード時に例外「UserAuth::ActivatedUser」が発生し、messageが「TokenUser already activated」となること' do
      expect do
        UserAuth::ActivateToken.decode(@encode_token_ins.token)
      end.to raise_error(UserAuth::ActivatedUser, "TokenUser already activated")
    end
  end
  context 'PasswordResetToken' do
    before do
      encode_token_ins = UserAuth::PasswordResetToken.encode(@user.id)
      @lifetime = encode_token_ins.lifetime
      @token = encode_token_ins.token
    end
    it '有効期限が30分であること' do
      expect(@lifetime).to match(30.minute)
    end
    it 'typクレームが「password_reset」でない場合、デコード時に例外「UserAuth::InvalidTypError」が発生し、messageが「Invalid type. Expected access, received <受け取ったトークンのtype名>」となること' do
      other_type_token = UserAuth::RefreshToken.encode(@user.id).token
      expect do
        UserAuth::PasswordResetToken.decode(other_type_token)
      end.to raise_error(UserAuth::InvalidTypError, "Invalid type. Expected password_reset, received refresh")
    end
  end
  context 'EmailChangeToken' do
    before do
      encode_token_ins = UserAuth::EmailChangeToken.encode(@user.id, "change@abc.com")
      @lifetime = encode_token_ins.lifetime
      @token = encode_token_ins.token
    end
    it '有効期限が30分であること' do
      expect(@lifetime).to match(30.minute)
    end
    it '「change_email」クレームがないトークンの場合、デコード時に例外「JWT::MissingRequiredClaim」が発生し、messageが「Missing required claim change_email」となること' do
      no_change_email_claim_token = UserAuth::RefreshToken.encode(@user.id).token
      expect do
        UserAuth::EmailChangeToken.decode(no_change_email_claim_token)
      end.to raise_error(JWT::MissingRequiredClaim, "Missing required claim change_email")
    end
    it 'typクレームが「change_email」でない場合、デコード時に例外「UserAuth::InvalidTypError」が発生し、messageが「Invalid type. Expected access, received <受け取ったトークンのtype名>」となること' do
      token_base_ins = UserAuth::TokenBase.new(:aaa)
      add_payload = {
        change_email: "change@abc.com"
      }
      other_type_token = token_base_ins.encode(@user.id, add_payload: add_payload).token
      expect do
        UserAuth::EmailChangeToken.decode(other_type_token)
      end.to raise_error(UserAuth::InvalidTypError, "Invalid type. Expected email_change, received aaa")
    end
  end
end
