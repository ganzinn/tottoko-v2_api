class Api::V1::UsersController < ApplicationController

  def create
    user = User.new(user_create_params)
    if user.save
      user.send_activation_email
      render status: 200, json: {success: true }
    else
      message = Utils::extract_when_one(user.errors.full_messages)
      response_4XX(422, code: "unprocessable", message: message)
    end
  end

  private

  def user_create_params
    params.require(:user)
    .permit(
      :name,
      :email,
      :password,
      :password_confirmation
    )
  end
end
