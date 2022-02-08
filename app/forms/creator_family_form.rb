class CreatorFamilyForm
  include ActiveModel::Model
  attr_accessor :name,
                :date_of_birth,
                :gender_id,
                :user_id
  
  attr_reader   :relation_id

  def relation_id=(relation_id)
    @relation_id = relation_id.to_i
  end

  # バリデーション -------------------------------------------------
  ALLOW_VALUES_RELATION_ID = [1, 2] # 「パパ・ママ」のみ
  validates :relation_id,
    presence: true,
    inclusion: {
      in: ALLOW_VALUES_RELATION_ID,
      allow_blank: true
    }
  # ----------------------------------------------------------------
  
  def save
    return if invalid?

    ActiveRecord::Base.transaction do
      creator = Creator.create!(
        name: name,
        date_of_birth: date_of_birth,
        gender_id: gender_id
      )
      Family.create!(
        user_id: user_id,
        creator_id: creator.id,
        relation_id: relation_id
      )
    end
  rescue ActiveRecord::RecordInvalid => e
    e.record.errors.each do |error|
      errors.add(error.attribute, error.message)
    end
    false
  end

end
