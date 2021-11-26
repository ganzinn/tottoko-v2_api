require 'jwt'

module UserAuth
  class EncodeToken
    include TokenEncryptCommon

    attr_reader :user_id, :lifetime, :payload, :header, :token

    def initialize(user_id, add_payload, override_lifetime: nil)
      @user_id = user_id
      @lifetime = override_lifetime || default_lifetime
      @payload = default_payload.merge(add_payload)
      @header = header_field
      @token = JWT.encode(@payload, secret_key, algorithm, @header)
    end

    # lifetimeの日本語テキストを返す
    def lifetime_text
      time, period = @lifetime.inspect.sub(/s\z/, "").split
      time + I18n.t("datetime.periods.#{period}", default: "")
    end

    private

    def default_lifetime
      30.minute
    end

    # user_id暗号化
    def encrypt_for_user_id
      crypt.encrypt_and_sign(@user_id.to_s, purpose: crypt_purpose_for_user_id)
    end

    # 有効期限をUnixtimeで返す
    def token_expiration
      @lifetime.from_now.to_i
    end

    def default_payload
      {
        sub: encrypt_for_user_id,
        exp: token_expiration
      }
    end

    def header_field
      {
        typ: "JWT",
        alg: algorithm
      }
    end
  end
end
