class Api::V1::MeController < ApplicationController
  include LoginResponse

  before_action :access_token_validate, only: [:show, :email_change_entry]
  before_action :activate_token_validate, only: [:activate]
  before_action :password_reset_token_validate, only: [:password_reset]
  before_action :email_change_token_validate, only: [:email_change]

  def show
    render json: {success: true, user: authorize_user.as_json(only: [:name, :email, :created_at])}
  end

  def activate
    @user = activate_target
    if @user.activate
      set_refresh_token
      render json: login_response_hash
    else
      response_4XX(422, code: "unprocessable", messages: @user.errors.full_messages)
    end
  end

  def password_reset
    user = password_reset_target
    if user.update(password_reset_params)
      render status: 200, json: {success: true }
    else
      response_4XX(422, code: "unprocessable", messages: user.errors.full_messages)
    end
  end

  def email_change_entry
    user = authorize_user
    user.email = email_change_entry_params[:email]
    if user.valid?
      user.send_email_change_email
      render status: 200, json: {success: true }
    else
      response_4XX(422, code: "unprocessable", messages: user.errors.full_messages)
    end
  end

  def email_change
    user = email_change_target
    if user.update(email: change_email)
      render status: 200, json: {success: true }
    else
      response_4XX(422, code: "unprocessable", messages: user.errors.full_messages)
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


  def email_change_entry_params
    params.require(:user)
    .permit(
      :email
    )
  end


  def email_change_token_validate
    email_change_token = token_from_header
    @email_change_token_ins = UserAuth::EmailChangeToken.new(email_change_token, method(:response_4XX))
    @email_change_token_ins.decode_token_validate
  end

  def email_change_target
    @email_change_token_ins.token_user
  end

  def change_email
    @email_change_token_ins.payload_change_email
  end


  def token_from_header
    request.headers["Authorization"]&.split&.last
  end

end