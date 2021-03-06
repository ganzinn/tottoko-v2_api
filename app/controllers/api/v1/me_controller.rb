class Api::V1::MeController < ApplicationController
  include LoginResponse

  before_action :access_token_validate, only: [:show, :update, :email_change_entry]
  before_action :activate_token_validate, only: [:activate]
  before_action :password_reset_token_validate, only: [:password_reset]
  before_action :email_change_token_validate, only: [:email_change]

  def show
    @user = authorize_user
    render status: 200, json: { success: true, user: @user.as_json(only: [:name, :email], methods: :original_avatar_url)}
  end

  def update
    @user = authorize_user
    if @user.update(user_update_params)
      @user.avatar.purge if params[:regd_avatar_del]
      render status: 200, json: { success: true, user: @user.as_json(only: [:name, :email], methods: :avatar_url)}
    else
      response_4XX(422, code: "unprocessable", messages: @user.errors.full_messages)
    end
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
      user.forget
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
    @user = email_change_target
    if @user.authenticate(email_change_params[:password])
      if @user.update(email: change_email)
        @user.forget
        set_refresh_token
        render json: login_response_hash
      else
        response_4XX(422, code: "unprocessable", messages: @user.errors.full_messages)
      end
    else
      code = "password_error"
      messages = ["???????????????????????????????????????"]
      response_4XX(401, code: code, messages: messages )
    end
  end

  private

  def user_update_params
    params.require(:user).permit(
      :name,
      :avatar
    )
  end

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

  def email_change_params
    params.require(:user)
    .permit(
      :password
    )
  end

  def change_email
    @email_change_token_ins.payload_change_email
  end


  def token_from_header
    request.headers["Authorization"]&.split&.last
  end

end