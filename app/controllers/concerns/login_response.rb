module LoginResponse
  private

  def set_refresh_token
    encode_refresh_token_ins = UserAuth::RefreshToken.encode(@user.id)
    @user.remember_jti!(encode_refresh_token_ins.payload[:jti])
    cookies.delete(:refresh_token)
    cookies[:refresh_token] = {
      value: encode_refresh_token_ins.token,
      expires: Time.at(encode_refresh_token_ins.payload[:exp]),
      secure: Rails.env.production?,
      http_only: true
    }
  end

  def login_response_hash
    encode_access_token_ins = UserAuth::AccessToken.encode(@user.id)
    hash = {
      success: true,
      token: encode_access_token_ins.token,
      expires: encode_access_token_ins.payload[:exp],
      user: @user.as_json(only: [:name, :email], methods: :resize_avatar_url)
    }
    return hash
  end
end