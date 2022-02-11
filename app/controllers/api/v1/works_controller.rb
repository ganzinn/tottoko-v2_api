class Api::V1::WorksController < ApplicationController
  before_action :conditional_access_token_validate, only: [:show]
  before_action :access_token_validate,             only: [:update, :destroy]
  before_action :set_work
  before_action :show_permission_check,             only: [:show]
  before_action :edit_permission_check,             only: [:update, :destroy]

  def show
  end

  def update
    if @work.update(work_params)
      render status: 200, json: {success: true, work: {id: @work.id} }
    else
      response_4XX(422, code: "unprocessable", messages: @work.errors)
    end
  end

  def destroy
    if @work.destroy
      render status: 200, json: {success: true }
    else
      response_4XX(422, code: "unprocessable", messages: @work.errors)
    end
  end

  private

  # 同じbefore_actionがあると最後のメソッドのみの実行となるため、条件付きメソッドとして別に定義
  def conditional_access_token_validate
    access_token_validate if request.headers["Authorization"]&.split&.last
  end

  def set_work
    @work = Work.find(params[:id]) # 存在しない場合、404
  end

  def work_params
    params.require(:work).permit(
      :date,
      :title,
      :description,
      :scope_id,
      images: []
    )
  end

  def show_permission_check
    if authorize_user.present?
      @family = Family.find_by!(user_id: authorize_user.id, creator_id: @work.creator_id)
      unless @work.scope_id == 4 || (@family && @work.scope.targets.include?(@family.relation_id))
        response_4XX(401, code: "unauthorized", messages: {base: ['権限がありません']})
      end
    else
      unless @work.scope_id == 4
        response_4XX(401, code: "unauthorized", messages: {base: ['権限がありません']})
      end
    end
  end

  def edit_permission_check
    family = Family.find_by!(user_id: authorize_user.id, creator_id: @work.creator_id)
    unless family.work_edit_permission_check
      response_4XX(401, code: "unauthorized", messages: {base: ['権限がありません']})
    end
  end

end
