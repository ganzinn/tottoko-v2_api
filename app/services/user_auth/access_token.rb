module UserAuth
  class AccessToken

    @@token_ins = UserAuth::TokenBase.new(:access)

    class << self
      def encode(user_id)
        # @@token_ins.encode(user_id, override_lifetime: 30.second)
        @@token_ins.encode(user_id) # lifetimeデフォルト（30.minute）
      end

      def decode(token)
        @@token_ins.decode(token)
      end
    end

    def initialize(token, response_4XX)
      @token = token
      @response_4XX = response_4XX
    end

    def decode_token_validate
      @@token_ins.token_not_set_response(@response_4XX) and return if @token.nil?
      begin
        token_user
      rescue JWT::ExpiredSignature
        @@token_ins.token_expired_response(@response_4XX)
      rescue JWT::DecodeError, UserAuth::DecodeError => e
        @@token_ins.token_invalid_response(@response_4XX, e)
      end
    end

    def token_user
      @_token_user ||= self.class.decode(@token).user
    end
  end
end
