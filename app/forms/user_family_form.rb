class UserFamilyForm
  include ActiveModel::Model
  attr_accessor :email,
                :user_id,
                :creator_id
  
  attr_reader   :relation_id

  def relation_id=(relation_id)
    @relation_id = relation_id.to_i
  end

  # バリデーション -------------------------------------------------
  with_options presence: true do
    validates :email
    validates :creator_id
    validates :relation_id
  end

  validate :email_presence?, if: -> { email.present? }
  def email_presence?
    errors.add( :email, :must_exist ) if User.find_by_activated(email).blank?
  end
  
  validate :creator_presence?, if: -> { creator_id.present? }
  def creator_presence?
    errors.add( :creator_id, :must_exist ) unless Creator.exists?(creator_id)
  end

  # ----------------------------------------------------------------
  
  def save
    return if invalid?

    user_id = User.find_by_activated(email)&.id
    Family.create!(
      user_id: user_id,
      creator_id: creator_id,
      relation_id: relation_id
    )

  rescue ActiveRecord::RecordInvalid => e
    e.record.errors.each do |error|
      errors.add(error.attribute, error.message)
    end
    false
  end

end
