class Creator < ApplicationRecord
  include Rails.application.routes.url_helpers
  extend ActiveHash::Associations::ActiveRecordExtensions
  belongs_to_active_hash :gender

  has_many :families, dependent: :destroy
  has_many :users, through: :families
  has_many :works, dependent: :destroy
  has_one_attached :avatar

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

  def age
    today = Time.zone.today

    years = (today.strftime('%Y%m%d').to_i - date_of_birth.strftime('%Y%m%d').to_i) / 10_000.to_i
    months = (today.strftime('%m%d').to_i - date_of_birth.strftime('%m%d').to_i) / 100.to_i
    months += 12 if months.negative?
    {'years'=> years, 'months'=> months}
  end

  def original_avatar_url
    return nil unless avatar.attached?
    url_for(avatar)
  end

  def avatar_url
    return nil unless avatar.attached?
    url_for(avatar.variant(resize:'100x100').processed)
  end

end
