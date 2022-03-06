class Creator < ApplicationRecord
  extend ActiveHash::Associations::ActiveRecordExtensions
  belongs_to_active_hash :gender

  has_many :families, dependent: :destroy
  has_many :users, through: :families
  has_many :works, dependent: :destroy

  # バリデーション -------------------------------------------------
  validates :name,
    presence: true,
    length: {
      maximum: 40,
      allow_blank: true
    }

  validates :date_of_birth,
    date_format: true


  ALLOW_VALUES_GENDER_ID = [1, 2, 3]
  validates :gender_id,
    inclusion: {
      in: ALLOW_VALUES_GENDER_ID,
      allow_blank: true
    }
  # ----------------------------------------------------------------
end
