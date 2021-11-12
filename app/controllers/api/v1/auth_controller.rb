class Api::V1::AuthController < ApplicationController
  include UserAuth::UserSessionize

  rescue_from UserAuth.not_found_exception_class, with: :unauthorized
  rescue_from JWT::InvalidJtiError, with: :invalid_jti

  before_action :sessionize_user, only: [:refresh]
  before_action :authenticate_user, only: [:logout]

  def login
    authenticate
    @user = target_user
    set_refresh_token_to_cookie
    render json: login_response
  end

  def refresh
    @user = session_user
    set_refresh_token_to_cookie
    render json: login_response
  end

  def logout
    current_user.forget
    delete_session
    if cookies[session_key].nil?
      head(:ok)
    else
      response_500("セッション削除に失敗しました")
    end
  end

  def activate
    activate_token = params.require(:token)
    activate_token_ins = User.decode_access_token(activate_token)
    @user = activate_token_ins.entity_for_user
    payload_obj = activate_token_ins.payload["obj"]
    if @user.activated == false && payload_obj == "account_activation"
      @user.update_attribute(:activated, true)
      delete_session
      set_refresh_token_to_cookie
      render json: login_response
    else
      invalid_url
    end
  rescue UserAuth.not_found_exception_class,JWT::DecodeError, JWT::EncodeError
    invalid_url
  end

  private

    # params[:email]からアクティブなユーザーを返す
    def target_user
      @_target_user ||= User.find_by_activated(auth_params[:email])
    end

    # ログインユーザーが居ない、もしくはpasswordが一致しない場合404を返す
    def authenticate
      unless target_user.present? && target_user.authenticate(auth_params[:password])
        raise UserAuth.not_found_exception_class
      end
    end

    # refresh_tokenを再生成し、cookieにセットする
    def set_refresh_token_to_cookie
      cookies[session_key] = {
        value: refresh_token,
        expires: refresh_token_expiration,
        secure: Rails.env.production?,
        http_only: true
      }
    end

    # ログイン時のデフォルトレスポンス
    def login_response
      {
        success: true,
        token: access_token,
        expires: access_token_expiration,
        # user: @user.response_json(sub: access_token_subject)
        user: @user.response_json
      }
    end

    # リフレッシュトークンのインスタンス生成
    def encode_refresh_token
      @_encode_refresh_token ||= @user.encode_refresh_token
    end

    # リフレッシュトークン
    def refresh_token
      encode_refresh_token.token
    end

    # リフレッシュトークンの有効期限
    def refresh_token_expiration
      Time.at(encode_refresh_token.payload[:exp])
    end

    # アクセストークンのインスタンス生成
    def encode_access_token
      @_encode_access_token ||= @user.encode_access_token
    end

    # アクセストークン
    def access_token
      encode_access_token.token
    end

    # アクセストークンの有効期限
    def access_token_expiration
      encode_access_token.payload[:exp]
    end

    def decode_access_token(token)
      @_decode_access_token ||= User.decode_access_token(token)
    end

    def unauthorized
      response_401("ユーザー認証に失敗しました。")
    end

    # decode jti != user.refresh_jti のエラー処理
    def invalid_jti
      response_401("セッションが更新されたため、以前のセッションは破棄されました。")
    end

    def invalid_url
      response_401("無効なURLです。")
    end

    def auth_params
      params.require(:auth).permit(:email, :password)
    end

end
