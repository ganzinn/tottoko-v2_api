class Api::V1::WorkCommentsController < ApplicationController
  include Pagination

  before_action :conditional_access_token_validate, only: [:index]
  before_action :access_token_validate,             only: [:create]
  before_action :set_work
  before_action :index_permission_check,            only: [:index]
  before_action :create_permission_check,           only: [:create]
  
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
    per = params[:per] || 5

    @comments = Comment.where( work_id: @work.id).order(created_at: :DESC).includes(:user).page(page).per(per)
    # if @comments.blank?
    #   response_4XX(404, code: "not_found", messages: ['見つかりません']) and return
    # end
    @current_user_id = authorize_user ? authorize_user.id : nil

    # ページネーション情報の取得
    @pagination = pagination(@comments)
  end

  private

  def conditional_access_token_validate
    access_token_validate if request.headers["Authorization"]&.split&.last
  end

  def set_work
    @work = Work.find(params[:work_id])
    rescue ActiveRecord::RecordNotFound => e
      response_4XX(404, code: "not_found", messages: ['見つかりません'])
  end

  def index_permission_check
    if authorize_user.present?
      family = Family.find_by(user_id: authorize_user.id, creator_id: @work.creator_id)
      unless @work.scope_id == 4 || (family && @work.scope.targets.include?(family.relation_id))
        response_4XX(401, code: "unauthorized", messages: ['権限がありません'])
      end
    else
      unless @work.scope_id == 4
        response_4XX(401, code: "unauthorized", messages: ['権限がありません'])
      end
    end
  end

  def create_permission_check
    family = Family.find_by(user_id: authorize_user.id, creator_id: @work.creator_id)
    unless @work.scope_id == 4 || (family && @work.scope.targets.include?(family.relation_id))
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
