module UserAuth
  class RefreshToken

    @@token_ins = UserAuth::TokenBase.new(:refresh)
    @@add_claim_for_jti = "jti"

    class << self
      def encode(user_id)
        add_payload = {
          @@add_claim_for_jti.to_sym => jwt_id
        }
        override_lifetime = 1.day
        @@token_ins.encode(user_id, add_payload: add_payload, override_lifetime: override_lifetime)
      end

      def decode(token)
        add_required_claims = [
          @@add_claim_for_jti
        ]
        decode_ins = @@token_ins.decode(token, add_required_claims: add_required_claims)
        verify_jti(decode_ins.user, decode_ins.payload[@@add_claim_for_jti])
        return decode_ins
      end

      private

      def jwt_id
        Digest::MD5.hexdigest(SecureRandom.uuid)
      end

      def verify_jti(user, payload_jti)
        expected_jti = user.refresh_jti
        if payload_jti != expected_jti
          raise(UserAuth::InvalidJtiError, "Invalid refresh_jti. Received #{payload_jti || '<none>'} not included session")
        end
      end
    end

    def initialize(cookies, response_4XX)
      @cookies = cookies
      @token = cookies[:refresh_token]
      @response_4XX = response_4XX
    end

    def decode_token_validate
      @@token_ins.token_not_set_response(@response_4XX) and return if @token.nil?
      begin
        token_user
      rescue JWT::ExpiredSignature
        delete_cookie_token
        @@token_ins.token_expired_response(@response_4XX)
      rescue JWT::DecodeError, UserAuth::DecodeError => e
        delete_cookie_token
        @@token_ins.token_invalid_response(@response_4XX, e)
      end
    end

    def token_user
      @_token_user ||= self.class.decode(@token).user
    end

    private

    def delete_cookie_token
      @cookies.delete(:refresh_token)
    end
  end
  class InvalidJtiError < UserAuth::DecodeError; end
end
