module UserAuth
  class EmailChangeToken

    @@token_ins = UserAuth::TokenBase.new(:email_change)
    @@add_claim_for_change_email = "change_email"

    class << self
      def encode(user_id, change_email)
        add_payload = {
          @@add_claim_for_change_email.to_sym => change_email
        }
        @@token_ins.encode(user_id, add_payload: add_payload)
      end

      def decode(token)
        add_required_claims = [
          @@add_claim_for_change_email
        ]
        @@token_ins.decode(token, add_required_claims: add_required_claims)
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
      @_token_user ||= decode_token_ins.user
    end

    def payload_change_email
      decode_token_ins.payload["change_email"]
    end

    private

    def decode_token_ins
      @_decode_token_ins ||= self.class.decode(@token)
    end
  end
end
