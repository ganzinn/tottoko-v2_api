class Api::V1::FamiliesController < ApplicationController
  before_action :access_token_validate
  before_action :create_permission_check, only: [:create]
  before_action :delete_permission_check, only: [:destroy]

  def create
    target_user_family = UserFamilyForm.new(create_family_params)
    if target_user_family.save
      render status: 201, json: {success: true}
    else
      response_4XX(422, code: "unprocessable", messages: target_user_family.errors.full_messages)
    end
  end

  def destroy
    if @target_user_family.destroy
      render status: 200, json: {success: true}
    else
      response_4XX(422, code: "unprocessable", messages: target_user_family.errors.full_messages)
    end
  end

  private

  def create_permission_check
    current_user_family = Family.find_by(user_id: authorize_user.id, creator_id: create_family_params[:creator_id])
    unless current_user_family&.family_create_permission_check
      response_4XX(401, code: "unauthorized", messages: ['権限がありません'])
    end
  end

  def create_family_params
    params.require(:family).permit(
      :email,
      :relation_id
    ).merge(
      creator_id: params[:creator_id]
    )
  end


  def delete_permission_check
    @target_user_family = Family.find(params[:id])
    current_user_family = Family.find_by(user_id: authorize_user.id, creator_id: params[:creator_id])
    unless current_user_family&.family_remove_permission_check(@target_user_family)
      response_4XX(401, code: "unauthorized", messages: ['権限がありません'])
    end
  end

end
