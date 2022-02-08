class Api::V1::MyCreatorsController < ApplicationController
  before_action :access_token_validate

  def create
    creator_family_form = CreatorFamilyForm.new(creator_family_form_params)
    if creator_family_form.save
      render status: 201, json: {success: true }
    else
      response_4XX(422, code: "unprocessable", messages: creator_family_form.errors)
    end
  end

  def index
    @my_creators = Creator.where(
      id: Family.where(user_id: authorize_user.id).select(:creator_id)
    )
  end

  private

  def creator_family_form_params
    params.require(:creator).permit(
      :name,
      :date_of_birth,
      :gender_id,
      :relation_id
    ).merge(
      user_id: authorize_user.id
    )
  end

end