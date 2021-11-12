module UserAuth
  module UserAuthenticate

    # 認証済みのユーザーが居ればtrue、存在しない場合は401を返す
    def authenticate_user
      current_user.present? || unauthorized_user
    end
  
    private
  
      # リクエストヘッダートークンを取得する
      def token_from_request_headers
        request.headers["Authorization"]&.split&.last
      end

      # トークンインスタンス生成（デコード）
      def decode_access_token_ins(token)
        @_decode_access_token_ins ||= User.decode_access_token(token)
      end

      # access_tokenから有効なユーザーを取得する
      def fetch_user_from_access_token
        token_ins = decode_access_token_ins(token_from_request_headers)
        payload_obj = token_ins.payload["obj"]
        if payload_obj == "user_authenticate" # トークン用途検証
          token_ins.entity_for_user
        else
          nil
        end
      rescue UserAuth.not_found_exception_class, JWT::DecodeError, JWT::EncodeError
        nil
      end
  
      # tokenのユーザーを返す
      def current_user
        return nil unless token_from_request_headers
        @_current_user ||= fetch_user_from_access_token
      end
  
      # 認証エラー
      def unauthorized_user
        cookies.delete(UserAuth.session_key)
        msg = "認証情報が不正です。"
        render status: 401, json: { success: false, error: msg }
      end
  end
end
