require 'jwt'

module UserAuth
  class AccessToken
    include TokenCommons

    attr_reader :token, :encode_user_id, :payload, :lifetime

    # 使用する引数：
    #  decode：   token
    #  ecode ：   user_id, payload（任意） ※新規登録のメール認証時のみpayloadにlifetimeを設定することで有効期限を延長できるよう設置。
    def initialize(token: nil, user_id: nil, payload: {})
      if token.present?
        # decode
        @token = token
        @payload = JWT.decode(@token.to_s, decode_key, true, verify_claims).first
        @encode_user_id = get_user_id_from(@payload)
      else
        # encode
        @encode_user_id = encrypt_for(user_id)
        @lifetime = payload[:lifetime] || UserAuth.access_token_lifetime
        @payload = claims.merge(payload.except(:lifetime))
        @token = JWT.encode(@payload, encode_key, algorithm, header_fields)
      end
    end

    # 暗号化された@user_idからユーザーを取得する
    def entity_for_user
      User.find(decrypt_for(@encode_user_id))
    end

    # @lifetimeの日本語テキストを返す
    def lifetime_text
      time, period = @lifetime.inspect.sub(/s\z/, "").split
      time + I18n.t("datetime.periods.#{period}", default: "")
    end

    private

      ## エンコードメソッド

      # 有効期限をUnixtimeで返す(必須)
      def token_expiration
        @lifetime.from_now.to_i
      end

      # issuerを返す
      def token_issuer
        UserAuth.token_issuer
      end

      # audienceを返す
      def token_audience
        UserAuth.token_audience
      end

      # エンコード時のデフォルトクレーム
      def claims
        _claims = {}
        _claims[:exp] = token_expiration
        _claims[user_claim] = @encode_user_id
        _claims[:iss] = token_issuer if token_issuer.present?
        _claims[:aud] = token_audience if token_audience.present?
        _claims
      end

      ## デコードメソッド

      # デコード時のデフォルトオプション
      # Doc: https://github.com/jwt/ruby-jwt
      # default: https://www.rubydoc.info/github/jwt/ruby-jwt/master/JWT/DefaultOptions
      def verify_claims
        {
          verify_expiration: true, # 有効期限の検証
          algorithm: algorithm     # decode時のアルゴリズム
        }
      end
  end
end
