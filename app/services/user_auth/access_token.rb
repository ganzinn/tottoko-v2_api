require 'jwt'

module UserAuth
  class AccessToken
    include TokenCommons

    attr_reader :token, :encode_user_id, :payload, :lifetime

    # 使用する引数：
    #  decode：   token
    #  encode：   user_id, option_payload（任意）
    def initialize(token: nil, user_id: nil, option_payload: {})
      if token.present?
        # decode
        @token = token
        @payload = JWT.decode(@token.to_s, decode_key, true, verify_payload).first
        @encode_user_id = get_user_id_from(@payload)
      else
        # encode
        @encode_user_id = encrypt_for(user_id)
        @lifetime = option_payload[:lifetime] || UserAuth.access_token_lifetime
        @payload = default_payload.merge(option_payload.except(:lifetime))
        @token = JWT.encode(@payload, encode_key, algorithm, header_fields)
      end
    end

    # 暗号化された@user_idからユーザーを取得する
    def entity_for_user
      User.find(decrypt_for(@encode_user_id))
    end

    private

      ## エンコードメソッド ------------------------------

      # 有効期限をUnixtimeで返す
      def token_expiration
        @lifetime.from_now.to_i
      end

      # エンコード時のデフォルトペイロード
      def default_payload
        {
          user_claim => @encode_user_id,
          exp: token_expiration,
          iss: token_issuer,
          aud: token_audience,
          obj: :user_authenticate         # user_authenticate以外の用途（account_activationなど）でトークン発行の場合はencode時「option_payload」で上書き
        }
      end

      ## デコードメソッド --------------------------------

      # ペイロードの検証
      # ruby-jwtのデフォルト検証: https://www.rubydoc.info/github/jwt/ruby-jwt/master/JWT/DefaultOptions
      def verify_payload
        {
          verify_expiration: true, # 有効期限の検証（必須）
          algorithm: algorithm     # decode時のアルゴリズムの検証（必須）
        }
      end
  end
end
