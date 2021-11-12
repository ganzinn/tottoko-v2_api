module UserAuth
  module TokenGenerate
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      # アクセストークンのインスタンス生成(オプション => type: )
      def decode_access_token(token)
        AccessToken.new(token: token)
      end
      
      # アクセストークンのuserを返す
      def from_access_token(token)
        AccessToken.new(token: token).entity_for_user
      end

      # リフレッシュトークンのuserを返す
      def from_refresh_token(token)
        RefreshToken.new(token: token).entity_for_user
      end
    end
  
    # アクセストークンのインスタンス生成(期限変更 => lifetime: 10.minute)
    def encode_access_token(option_payload = {})
      AccessToken.new(user_id: id, option_payload: option_payload)
    end
  
    # リフレッシュトークンのインスタンス生成
    def encode_refresh_token
      RefreshToken.new(user_id: id)
    end
  end
end
