require 'jwt'

module UserAuth
  class DecodeToken
    include TokenEncryptCommon

    attr_reader :token, :header, :payload, :user

    def initialize(token, expected_typ, add_required_claims)
      @token = token
      @required_claims = ["exp", "sub", "typ"].concat(add_required_claims)
      @payload, @header = JWT.decode(@token.to_s, secret_key, true, verify_claim)
      verify_typ(expected_typ)
      @user = user_from_payload_sub
    end

    private

    def decrypt_user_id
      crypt.decrypt_and_verify(@payload["sub"].to_s, purpose: crypt_purpose_for_user_id)
    rescue
      nil
    end

    def user_from_payload_sub
      user_id = decrypt_user_id
      begin
        User.find(user_id)
      rescue ActiveRecord::RecordNotFound
        raise(UserAuth::UserNotFoundError, "User not Found. Received user_id #{user_id || '<none>'}")
      end
    end

    # ruby-jwtで行うクレーム検証
    def verify_claim
      {
        # JWTの仕様ではheaderのalgorithmで署名検証するが、想定外のalgorithmで署名検証した場合セキュリティリスクがあるため、
        # 事前に想定通りのalgorithmか検証（ruby-jwtデフォルト）
        algorithm: algorithm,
        required_claims: @required_claims,
        verify_expiration: true
      }
    end

    # typクレーム検証（ruby-jwtで行えないため追加）
    def verify_typ(expected_typ)
      payload_typ = @payload["typ"]
      if payload_typ != expected_typ
        raise(UserAuth::InvalidTypError, "Invalid type. Expected #{expected_typ}, received #{payload_typ || '<none>'}")
      end
    end
  end
  class InvalidTypError < UserAuth::DecodeError; end
  class UserNotFoundError < UserAuth::DecodeError; end
end
