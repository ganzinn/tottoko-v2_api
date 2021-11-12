class Api::V1::UsersController < ApplicationController
  before_action :authenticate_user, only: [:index]

  def index
    # users = User.all
    render json: {success: true, user: current_user.as_json(only: [:id, :name, :email, :created_at])}
  end

  def create
    user = User.new(user_params)
    if user.save
      user.send_activation_email
      render status: 201, json: {success: true }
    else
      render status: 422, json: {success: false, messages: user.errors.full_messages}
    end
  end

  private

    def user_params
      params.require(:user)
      .permit(
        :name,
        :email,
        :password,
        :password_confirmation
      )
    end
end
