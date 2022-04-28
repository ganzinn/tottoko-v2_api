class Comment < ApplicationRecord
  belongs_to :work
  belongs_to :user

  # バリデーション -------------------------------------------------
  validates :message,
  presence: true

  # ----------------------------------------------------------------

  # コメントの編集・削除権限チェック
  def edit_permission_check(target_user_id)
    return false if target_user_id == nil
    self.user_id == target_user_id
  end

end
