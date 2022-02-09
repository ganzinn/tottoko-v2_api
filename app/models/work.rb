class Work < ApplicationRecord
  extend ActiveHash::Associations::ActiveRecordExtensions
  belongs_to_active_hash :scope

  belongs_to :creator

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
end
