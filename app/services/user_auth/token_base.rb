module UserAuth
  class TokenBase
    def initialize(token_type)
      @token_type = token_type.to_s.underscore
    end

    def encode(user_id, add_payload: {}, override_lifetime: nil)
      payload = {
        typ: @token_type
      }.merge(add_payload)
      return UserAuth::EncodeToken.new(user_id, payload, override_lifetime: override_lifetime)
    end

    def decode(token)
      expected_typ = @token_type
      return UserAuth::DecodeToken.new(token, expected_typ)
    end

    def token_not_set_response(response_4XX)
      code = @token_type + "_token_not_set"
      message = @token_type.camelize + "Token が設定されていません"
      response_4XX.call(401, code: code, message: message)
    end

    def token_expired_response(response_4XX)
      code = @token_type + "_token_expired"
      message = @token_type.camelize + "Token の有効期限切れです"
      response_4XX.call(401, code: code, message: message)
    end

    def token_invalid_response(response_4XX, exception = nil)
      # yield if block_given?
      unless exception.nil?
        # 【TODO】ログ出力処理
      end
      code = @token_type + "_token_invalid"
      message = @token_type.camelize + "Token が有効ではありません"
      response_4XX.call(401, code: code, message: message)
    end
  end
end
