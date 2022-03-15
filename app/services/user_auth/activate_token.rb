module UserAuth
  class ActivateToken

    @@token_ins = UserAuth::TokenBase.new(:activate)

    class << self
      def encode(user_id)
        override_lifetime = 1.hour
        @@token_ins.encode(user_id, override_lifetime: override_lifetime)
      end

      def decode(token)
        decode_ins = @@token_ins.decode(token)
        activated_user?(decode_ins.user)
        return decode_ins
      end

      private
  
      def activated_user?(user)
        if user.activated == true
          raise(UserAuth::ActivatedUser, "TokenUser already activated")
        end
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
      rescue UserAuth::ActivatedUser
        already_activated_response
      rescue JWT::DecodeError, UserAuth::DecodeError => e
        @@token_ins.token_invalid_response(@response_4XX, e)
      end
    end

    def token_user
      @_token_user ||= self.class.decode(@token).user
    end

    private

    def already_activated_response
      code = "already_activated"
      message = "アカウントは既に有効化されています"
      messages = [message]
      @response_4XX.call(401, code: code, messages: messages) 
    end
  end
  class ActivatedUser < UserAuth::DecodeError; end
end
