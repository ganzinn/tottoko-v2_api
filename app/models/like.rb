class Like < ApplicationRecord
  belongs_to :work
  belongs_to :user

  # バリデーション -------------------------------------------------
  validate :dup_check, if: -> { work.present? && user.present?}
  def dup_check
    errors.add( :base, :taken ) if Like.find_by(work_id: work.id, user_id: user.id)
  end
  # ----------------------------------------------------------------

end
