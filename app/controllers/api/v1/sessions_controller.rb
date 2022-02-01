class Api::V1::SessionsController < ApplicationController
  include LoginResponse

  before_action :user_authenticate, only: [:login]
  before_action :refresh_token_validate, only: [:refresh, :logout]

  def login
    @user = login_user
    set_refresh_token
    render json: login_response_hash
  end

  def refresh
    @user = session_user
    set_refresh_token
    render json: login_response_hash
  end

  def logout
    if session_user.forget && cookies.delete(:refresh_token)
      render status: 200, json: {success: true }
    else
      code = :session_delete_fail
      messages = ["セッション削除に失敗しました"]
      response_500(code: code, messages: messages )
    end
  end

  private

  def user_authenticate
    unless login_user.present? && login_user.authenticate(login_params[:password])
      code = :authenticate_fail
      messages = ["認証に失敗しました"]
      response_4XX(401, code: code, messages: messages )
    end
  end

  def login_user
    @_login_user ||= User.find_by_activated(login_params[:email])
  end

  def login_params
    params.require(:auth).permit(:email, :password)
  end

  def refresh_token_validate
    @refresh_token_ins = UserAuth::RefreshToken.new(cookies, method(:response_4XX))
    @refresh_token_ins.decode_token_validate
  end

  def session_user
    @refresh_token_ins.token_user
  end
end
