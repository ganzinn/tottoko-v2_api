class Work < ApplicationRecord
  include Rails.application.routes.url_helpers
  extend ActiveHash::Associations::ActiveRecordExtensions
  belongs_to_active_hash :scope

  belongs_to :creator
  has_many_attached :images
  has_many :families, through: :creator
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :work_tag_relations, dependent: :destroy
  has_many :tags, through: :work_tag_relations

  # バリデーション -------------------------------------------------
  validates :date,
    date_format: true
  
  validates :title,
    length: { maximum: 40 }
  
  validates :description,
    length: { maximum: 255 }

  ALLOW_VALUES_SCOPE_ID = 1..4
  validates :scope_id,
    presence: true,
    inclusion: {
      in: ALLOW_VALUES_SCOPE_ID,
      allow_blank: true
    }

  validates :creator_id,
    presence: true

  validate :images_validate
  def images_validate
    # 必須入力
    return errors.add(:images, :blank) unless images.attached?

    # ファイルタイプ
    allow_filetype = ['image/jpeg', 'image/png']
    if images.attachments.any? { |attachment| !attachment.content_type.in?(allow_filetype) }
      errors.add(:images, :invalid_file_type)
    end
  end

  # ----------------------------------------------------------------

  # 一覧画面用画像データのURL取得
  def index_image_url
    return nil unless images.attached?
    url_for(images.first.variant(resize:'300x300').processed)
  end

  # 詳細画面用画像データのURL取得
  def detail_image_urls
    return nil unless images.attached?
    images.map { |image| url_for(image) }
  end

end
