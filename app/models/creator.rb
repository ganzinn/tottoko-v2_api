class Creator < ApplicationRecord
  extend ActiveHash::Associations::ActiveRecordExtensions
  belongs_to_active_hash :gender

  has_many :families, dependent: :destroy
  has_many :users, through: :families
  has_many :works, dependent: :destroy
end
