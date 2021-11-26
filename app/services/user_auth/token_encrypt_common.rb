module UserAuth
  module TokenEncryptCommon

    private

    def secret_key
      Rails.application.credentials.secret_key_base
    end
  
    # 署名アルゴリズム
    def algorithm
      "HS256"
    end
  
    # 暗号化インスタンス
    def crypt
      salt = "user_auth_salt"
      key_length = ActiveSupport::MessageEncryptor.key_len
      secret = Rails.application.key_generator.generate_key(salt, key_length)
      ActiveSupport::MessageEncryptor.new(secret)
    end

    # user_idの暗号、復号時のpurposeオプション
    def crypt_purpose_for_user_id
      :user_id
    end

  end
end
