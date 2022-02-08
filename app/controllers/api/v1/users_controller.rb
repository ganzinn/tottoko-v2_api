class Api::V1::UsersController < ApplicationController

  def create
    user = User.new(user_create_params)
    if user.save
      user.send_activation_email
      render status: 201, json: {success: true }
    else
      response_4XX(422, code: "unprocessable", messages: user.errors)
    end
  end

  def password_reset_entry
    user = User.find_by_activated(password_reset_entry_params[:email])
    user.present? && user.send_password_reset_email
    render status: 200, json: {success: true }
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

  def password_reset_entry_params
    params.require(:user)
    .permit(
      :email
    )
  end
end
