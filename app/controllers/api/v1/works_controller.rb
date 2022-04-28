class Api::V1::WorksController < ApplicationController
  before_action :conditional_access_token_validate, only: [:show]
  before_action :access_token_validate,             only: [:update, :destroy]
  before_action :set_work
  before_action :show_permission_check,             only: [:show]
  before_action :edit_permission_check,             only: [:update, :destroy]

  def show
  end

  def update
    work_tag_form = WorkTagForm.new(work_params, work: @work)
    if work_tag_form.save
      render status: 200, json: {success: true, work: {id: work_tag_form.work_id} }
    else
      response_4XX(422, code: "unprocessable", messages: work_tag_form.errors.full_messages)
    end
  end

  def destroy
    if @work.destroy
      render status: 200, json: {success: true }
    else
      response_4XX(422, code: "unprocessable", messages: @work.errors.full_messages)
    end
  end

  private

  # 同じbefore_actionがあると最後のメソッドのみの実行となるため、条件付きメソッドとして別に定義
  def conditional_access_token_validate
    access_token_validate if request.headers["Authorization"]&.split&.last
  end

  def set_work
    @work = Work.find(params[:id])
    rescue ActiveRecord::RecordNotFound => e
      response_4XX(404, code: "not_found", messages: ['見つかりません'])
  end

  def work_params
    params.require(:work).permit(
      :creator_id,
      :date,
      :title,
      :description,
      :scope_id,
      images: [],
      tags:[]
    )
  end

  def show_permission_check
    if authorize_user.present?
      @family = Family.find_by(user_id: authorize_user.id, creator_id: @work.creator_id)
      unless @work.scope_id == 4 || (@family && @work.scope.targets.include?(@family.relation_id))
        response_4XX(401, code: "unauthorized", messages: ['権限がありません'])
      end
    else
      unless @work.scope_id == 4
        response_4XX(401, code: "unauthorized", messages: ['権限がありません'])
      end
    end
  end

  def edit_permission_check
    family = Family.find_by(user_id: authorize_user.id, creator_id: @work.creator_id)
    unless family&.work_edit_permission_check
      response_4XX(401, code: "unauthorized", messages: ['権限がありません'])
    end
  end

end
