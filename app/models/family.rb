class Family < ApplicationRecord
  extend ActiveHash::Associations::ActiveRecordExtensions
  belongs_to_active_hash :relation

  belongs_to :user
  belongs_to :creator

  # バリデーション -------------------------------------------------
  ALLOW_VALUES_RELATION_ID = 1..8
  validates :relation_id,
    presence: true,
    inclusion: {
      in: ALLOW_VALUES_RELATION_ID,
      allow_blank: true
    }
  # ----------------------------------------------------------------

  # クリエーター（子ども）情報の編集・削除のチェック
  def creator_edit_permission_check
    # パパ・ママのみ
    [1, 2].include?(self.relation_id)
  end

  # クリエーター（子ども）の家族の解除権限チェック
  def remove_family_permission_check(cleator_family)
    if self.creator_edit_permission_check
      # 自身がパパ・ママの場合、自身以外との家族を解除可能
      self.user_id != cleator_family.user_id
    else
      # 自身がパパ・ママ以外の場合、自身のみ家族との解除可能
      user_family.user_id == self.user_id
    end
  end
end
