class Api::V1::LikesController < ApplicationController
  before_action :access_token_validate

  def create
    like = Like.new(work_id: params[:work_id], user_id: authorize_user.id)
    if like.save
      render status: 201, json: { success: true }
    else
      response_4XX(422, code: "unprocessable", messages: like.errors.full_messages)
    end
  end

  def destroy
    like = Like.find_by(work_id:params[:work_id], user_id: authorize_user.id)
    response_4XX(404, code: "not_found", messages: ['見つかりません']) and return if like.blank?
    if like&.destroy
      render status: 200, json: { success: true }
    else
      response_4XX(422, code: "unprocessable", messages: @like.errors.full_messages)
    end
  end

  def count
    @likes = Like.where(work_id:params[:work_id])
    @already_like = @likes&.find_by(user_id: authorize_user.id).present?
  end

end
