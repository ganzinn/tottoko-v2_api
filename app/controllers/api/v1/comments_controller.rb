class Api::V1::CommentsController < ApplicationController
  include Pagination

  before_action :access_token_validate
  before_action :set_work,                     only: [:create, :index]
  before_action :create_read_permission_check, only: [:create, :index]
  before_action :set_comment,                  only: [:update, :destroy]
  before_action :edit_permission_check,        only: [:update, :destroy]

  def create
    comment = Comment.new(create_comment_params)
    if comment.save
      render status: 201, json: {success: true, comment: {id: comment.id }}
    else
      response_4XX(422, code: "unprocessable", messages: comment.errors)
    end
  end

  def index
    # ページネーション初期化
    page = params[:page] || 1
    per = params[:per] || 20

    @comments = Comment.where( work_id: @work.id).order(:created_at).includes(:user).page(page).per(per)
    if @comments.blank?
      response_4XX(404, code: "not_found", messages: {base: ['見つかりません']}) and return
    end
    @current_user_id = authorize_user.id

    # ページネーション情報の取得
    @pagination = pagination(@comments)
  end

  def update
    if @comment.update(update_comment_params)
      render status: 200, json: { success: true }
    else
      response_4XX(422, code: "unprocessable", messages: @comment.errors)
    end
  end

  def destroy
    if @comment.destroy
      render status: 200, json: { success: true }
    else
      response_4XX(422, code: "unprocessable", messages: @comment.errors)
    end
  end

  private

  def set_work
    @work = Work.find(params[:work_id])
    rescue ActiveRecord::RecordNotFound => e
      response_4XX(404, code: "not_found", messages: {work_id: ['見つかりません']})
  end

  def create_read_permission_check
    family = Family.find_by(user_id: authorize_user.id, creator_id: @work.creator_id)
    unless family && @work.scope.targets.include?(family.relation_id)
      response_4XX(401, code: "unauthorized", messages: {base: ['権限がありません']})
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


  def set_comment
    @comment = Comment.find(params[:id])
    rescue ActiveRecord::RecordNotFound => e
      response_4XX(404, code: "not_found", messages: {id: ['見つかりません']})
  end

  def edit_permission_check
    # 【課題】作品の公開範囲が変更された場合、コメント投稿者が作品を閲覧できなく可能性がある。
    # その場合、自身が過去に投稿したコメントも見ることができなくなる。
    # ただし、APIとしては作品を閲覧できなくなってもコメントの編集・削除は可能とする。
    unless @comment.user_id == authorize_user.id
      response_4XX(401, code: "unauthorized", messages: {base: ['権限がありません']})
    end
  end

  def update_comment_params
    params.require(:comment).permit(
      :message
    )
  end

end
