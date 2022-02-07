class Family < ApplicationRecord
  extend ActiveHash::Associations::ActiveRecordExtensions
  belongs_to_active_hash :relation
  
  belongs_to :user
  belongs_to :creator
end
