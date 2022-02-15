class WorkTagForm
  include ActiveModel::Model
  attr_accessor :work_id,
                :date,
                :title,
                :description,
                :scope_id,
                :creator_id,
                :images,
                :tags

  # バリデーション -------------------------------------------------
  with_options presence: true do
    validates :date
    validates :scope_id
    validates :creator_id
    validates :images
  end

  # ----------------------------------------------------------------

  def initialize(attributes = nil, work: Work.new)
    @work = work
    attributes ||= default_attributes
    super(attributes)
  end
  
  def save
    return if invalid?

    ActiveRecord::Base.transaction do
      work_params = default_create_update_prams
      new_tags = []
      if tags.present?
        tags&.each do |tag|
          next if tag.blank?
          new_tags << Tag.where(name: tag).first_or_create
        end
        work_params.merge!({tags: new_tags})
      end
      work.update!(work_params)
      self.work_id = work.id
    end
  rescue ActiveRecord::RecordInvalid => e
    e.record.errors.each do |error|
      errors.add(error.attribute, error.message)
    end
    false
  end

  private

  attr_reader :work

  def default_attributes
    {
      work_id: work.id,
      date: work.date,
      title: work.title,
      description: work.description,
      scope_id: work.scope_id,
      creator_id: work.creator_id,
      images: work.images,
      tags: work.tags.pluck(:name)
    }
  end

  def default_create_update_prams
    {
      date: date,
      title: title,
      description: description,
      scope_id: scope_id,
      creator_id: creator_id,
      images: images
    }
  end

end
