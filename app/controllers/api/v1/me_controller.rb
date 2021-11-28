class Api::V1::MeController < ApplicationController
  include LoginResponse

  before_action :access_token_validate, only: [:show]
  before_action :activate_token_validate, only: [:activate]
  before_action :password_reset_token_validate, only: [:password_reset]

  def show
    render json: {success: true, user: authorize_user.as_json(only: [:name, :email, :created_at])}
  end

  def activate
    @user = activate_target
    if @user.activate
      set_refresh_token
      render json: login_response_hash
    else
      message = Utils::extract_when_one(@user.errors.full_messages)
      response_4XX(422, code: "unprocessable", message: message)
    end
  end

  def password_reset
    @user = password_reset_target
    if @user.update(password_reset_params)
      render status: 200, json: {success: true }
    else
      message = Utils::extract_when_one(@user.errors.full_messages)
      response_4XX(422, code: "unprocessable", message: message)
    end
  end

  private

  def activate_token_validate
    activate_token = token_from_header
    @activate_token_ins = UserAuth::ActivateToken.new(activate_token, method(:response_4XX))
    @activate_token_ins.decode_token_validate
  end

  def activate_target
    @activate_token_ins.token_user
  end

  def password_reset_token_validate
    password_reset_token = token_from_header
    @password_reset_token_ins = UserAuth::PasswordResetToken.new(password_reset_token, method(:response_4XX))
    @password_reset_token_ins.decode_token_validate
  end

  def password_reset_target
    @password_reset_token_ins.token_user
  end

  def password_reset_params
    params.require(:user)
    .permit(
      :password,
      :password_confirmation
    )
  end

  def token_from_header
    request.headers["Authorization"]&.split&.last
  end

end