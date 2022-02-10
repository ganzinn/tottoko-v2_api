class Work < ApplicationRecord
  include Rails.application.routes.url_helpers
  extend ActiveHash::Associations::ActiveRecordExtensions
  belongs_to_active_hash :scope

  belongs_to :creator
  has_many_attached :images

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
  # ----------------------------------------------------------------

  # 画像データのURL取得
  def image_urls
    # return nil unless images.attached?
    images.map { |image| url_for(image) }
  end

end
