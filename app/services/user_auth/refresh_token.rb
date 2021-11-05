require 'jwt'

module UserAuth
  class RefreshToken
    include TokenCommons

    attr_reader :token, :encode_user_id, :payload

    # 使用する引数：
    #  decode：   token
    #  ecode ：   user_id
    def initialize(token: nil, user_id: nil)
      if token.present?
        # decode
        @token = token
        @payload = JWT.decode(@token.to_s, decode_key, true, verify_claims).first
        @encode_user_id = get_user_id_from(@payload)
      else
        # encode
        @encode_user_id = encrypt_for(user_id)
        @payload = claims
        @token = JWT.encode(@payload, encode_key, algorithm, header_fields)
        remember_jti(user_id)
      end
    end

    # 暗号化されたuserIDからユーザーを取得する
    def entity_for_user(id = nil)
      id ||= @encode_user_id
      User.find(decrypt_for(id))
    end

    private

      ## エンコードメソッド

      # 有効期限をUnixtimeで返す(必須)
      def token_expiration
        UserAuth.refresh_token_lifetime.from_now.to_i
      end

      # jwt_idの生成(必須)
      # Digest::MD5.hexdigest => 複合不可のハッシュを返す
      # SecureRandom.uuid => 一意性の値を返す
      def jwt_id
        Digest::MD5.hexdigest(SecureRandom.uuid)
      end

      # エンコード時のデフォルトクレーム
      def claims
        {
          user_claim => @encode_user_id,
          jti: jwt_id,
          exp: token_expiration
        }
      end

      # @payloadのjtiを返す
      def payload_jti
        @payload.with_indifferent_access[:jti]
      end

      # jtiをUsersテーブルに保存する
      def remember_jti(user_id)
        User.find(user_id).remember(payload_jti)
      end

      ## デコードメソッド

      # デコード時のjwt_idを検証する(エラーはJWT::DecodeErrorに委託する)
      def verify_jti?(jti, payload)
        encode_user_id = get_user_id_from(payload)
        user = entity_for_user(encode_user_id) # not_found_exception
        user.refresh_jti == jti
        # user.refresh_jti[encode_user_id] && user.refresh_jti[encode_user_id]['jti'] == jit
      rescue UserAuth.not_found_exception_class
        false
      end

      # デコード時のデフォルトオプション
      # Doc: https://github.com/jwt/ruby-jwt
      # default: https://www.rubydoc.info/github/jwt/ruby-jwt/master/JWT/DefaultOptions
      def verify_claims
        {
          verify_expiration: true,           # 有効期限の検証するか(必須)
          verify_jti: proc { |jti, payload|  # トークンのjtiとテーブルのjtiの検証
            verify_jti?(jti, payload)
          },
          algorithm: algorithm               # decode時のアルゴリズム
        }
      end
  end
end
