module UserAuth
  module UserSessionize
    def sessionize_user
      session_user.present? || unauthorized_user
    end
  
    def session_key
      UserAuth.session_key
    end
  
    def delete_session
      cookies.delete(session_key)
    end
  
    private
  
      def token_from_cookies
        cookies[session_key]
      end
  
      def fetch_user_from_refresh_token
        User.from_refresh_token(token_from_cookies)
      rescue JWT::InvalidJtiError
        # jtiエラーの場合はcontrollerに処理を委任
        catch_invalid_jti
      rescue UserAuth.not_found_exception_class,JWT::DecodeError, JWT::EncodeError
        nil
      end
  
      def session_user
        return nil unless token_from_cookies
        @_session_user ||= fetch_user_from_refresh_token
      end
  
      def catch_invalid_jti
        delete_session
        raise JWT::InvalidJtiError
      end
  
      def unauthorized_user
        delete_session
        head(:unauthorized)
      end
  end
end