class WorkTagRelation < ApplicationRecord
  belongs_to :work
  belongs_to :tag
end
