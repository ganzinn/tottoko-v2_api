class Api::V1::WorkCommentsController < ApplicationController
  include Pagination

  before_action :access_token_validate
  before_action :set_work
  before_action :create_read_permission_check
  
  def create
    comment = Comment.new(create_comment_params)
    if comment.save
      render status: 201, json: {success: true, comment: {id: comment.id }}
    else
      response_4XX(422, code: "unprocessable", messages: comment.errors.full_messages)
    end
  end

  def index
    # ページネーション初期化
    page = params[:page] || 1
    per = params[:per] || 20

    @comments = Comment.where( work_id: @work.id).order(:created_at).includes(:user).page(page).per(per)
    if @comments.blank?
      response_4XX(404, code: "not_found", messages: ['見つかりません']) and return
    end
    @current_user_id = authorize_user.id

    # ページネーション情報の取得
    @pagination = pagination(@comments)
  end

  private

  def set_work
    @work = Work.find(params[:work_id])
    rescue ActiveRecord::RecordNotFound => e
      response_4XX(404, code: "not_found", messages: ['見つかりません'])
  end

  def create_read_permission_check
    family = Family.find_by(user_id: authorize_user.id, creator_id: @work.creator_id)
    unless family && @work.scope.targets.include?(family.relation_id)
      response_4XX(401, code: "unauthorized", messages: ['権限がありません'])
    end
  end

  def create_comment_params
    params.require(:comment).permit(
      :message
    ).merge(
      work_id: params[:work_id],
      user_id: authorize_user.id
    )
  end

end
