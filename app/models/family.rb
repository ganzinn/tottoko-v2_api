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

  validate :dup_check, if: -> { user.present? && creator.present?}
  def dup_check
    errors.add( :base, :user_already_registered ) if Family.find_by(user_id: user.id, creator_id: creator.id)
  end

  # ----------------------------------------------------------------

  # クリエーター情報の編集・削除権限チェック
  def creator_edit_permission_check
    # パパ・ママ・本人のみ
    [1, 2, 3].include?(self.relation_id)
  end

  # 家族招待権限チェック
  def family_create_permission_check
    # パパ・ママ・本人のみ
    [1, 2, 3].include?(self.relation_id)
  end

  # 家族解除権限チェック
  def family_remove_permission_check(cleator_family)
    # binding.pry
    if self.family_create_permission_check
      # 自身がパパ・ママ・本人の場合、自身以外との関係を解除可能
      self.user_id != cleator_family.user_id
    else
      # 自身がパパ・ママ・本人以外の場合、自身のみ関係を解除可能
      self.user_id == cleator_family.user_id
    end
  end

  # 作品情報の作成・編集・削除権限チェック
  def work_edit_permission_check
    # パパ・ママ・本人のみ
    [1, 2, 3].include?(self.relation_id)
  end
  
end
