class Api::V1::CommentsController < ApplicationController
  include Pagination

  before_action :access_token_validate
  before_action :set_comment
  before_action :edit_permission_check

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
