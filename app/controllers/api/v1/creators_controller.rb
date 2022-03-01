class Api::V1::CreatorsController < ApplicationController
  before_action :access_token_validate
  before_action :set_creator
  before_action :show_permission_check
  before_action :edit_permission_check, only: [:update, :destroy]

  def show
    @creator_families = Family.where(creator_id: @creator.id).order(:relation_id).includes(:user)
  end

  def update
    if @creator.update(creator_params)
      render status: 200, json: { success: true }
    else
      response_4XX(422, code: "unprocessable", messages: @creator.errors.full_messages)
    end
  end

  def destroy
    if @creator.destroy
      render status: 200, json: { success: true }
    else
      response_4XX(422, code: "unprocessable", messages: @creator.errors.full_messages)
    end
  end

  private

  def set_creator
    @creator = Creator.find(params[:id])
    rescue ActiveRecord::RecordNotFound => e
      response_4XX(404, code: "not_found", messages: ['見つかりません'])
  end

  def show_permission_check
    @family = Family.find_by(user_id: authorize_user.id, creator_id: @creator.id)
    # 家族のみ
    unless @family
      response_4XX(401, code: "unauthorized", messages: ['権限がありません'])
    end
  end

  def edit_permission_check
    # パパ・ママのみ
    unless @family&.creator_edit_permission_check
      response_4XX(401, code: "unauthorized", messages: ['権限がありません'])
    end
  end

  def creator_params
    params.require(:creator).permit(
      :name,
      :date_of_birth,
      :gender_id
    )
  end
end
