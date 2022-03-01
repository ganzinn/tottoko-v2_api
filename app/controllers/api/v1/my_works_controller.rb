class Api::V1::MyWorksController < ApplicationController
  include Pagination

  before_action :access_token_validate
  before_action :create_permission_check, only: [:create]

  def create
    work_tag_form = WorkTagForm.new(work_params)
    if work_tag_form.save
      render status: 201, json: {success: true, work: {id: work_tag_form.work_id} }
    else
      response_4XX(422, code: "unprocessable", messages: work_tag_form.errors.full_messages)
    end
  end

  def index
    # 閲覧可能なクリエーターの抽出。
    my_creator_ids = Family.where(user_id: authorize_user.id).pluck(:creator_id)
    select_my_creator_ids = my_creator_ids

    # ページネーション初期化
    page = params[:page] || 1
    per = params[:per] || 16


    # クエリパラメーター（配列）で出力するクリエーターを絞り込み
    if params[:creator_ids].present? && params[:creator_ids].instance_of?(Array)
      params[:creator_ids].map!(&:to_i) # 配列内の文字列を文字列から数値へ変換
      if (params[:creator_ids] - my_creator_ids).empty? # 対象のクリエーターが閲覧可能なクリエーターか確認
        select_my_creator_ids = params[:creator_ids]
      else
        response_4XX(400, code: "bad_request", messages: ['存在しない、または権限がありません']) and return
      end
    end

    # 対象作品の取得
    my_work_ids = []
    Work.joins(:families)
        .select('works.id AS id, works.scope_id AS scope_id, families.relation_id AS relation_id')
        .where(creator_id: select_my_creator_ids, families: { user_id: authorize_user.id })
        .find_each do |work|
          my_work_ids << work.id if work.scope_id == 4 || work.scope.targets.include?(work.relation_id)
        end
    @my_works = Work.where(id: my_work_ids)
                    
    # 条件絞り込み（タグAND条件）
    if params[:tags].present?
      tag_ids = Tag.where(name: params[:tags]).select(:id)
      tag_ids.find_each do |tag_id|
        @my_works = @my_works.where( id: WorkTagRelation.where( tag_id: tag_id).select(:work_id) )
      end
    end
    
    # インルード／ソート／ページネーション設定
    @my_works = @my_works
                .with_attached_images
                # .with_all_variant_records # variantイメージ先読み（rails7.0から使用可能【課題】）
                .includes(:creator)
                .includes(:tags)
                .order(date: :desc, updated_at: :desc)
                .page(page).per(per)

    # ページネーション情報の取得
    @pagination = pagination(@my_works)
  end

  private

  def create_permission_check
    family = Family.find_by!(user_id: authorize_user.id, creator_id: work_params[:creator_id])
    unless family.work_edit_permission_check
      response_4XX(401, code: "unauthorized", messages: ['権限がありません'])
    end
  end

  def work_params
    params.require(:work).permit(
      :date,
      :title,
      :description,
      :scope_id,
      :creator_id,
      images: [],
      tags: []
    )
  end
end
