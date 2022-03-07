class DeleteNotNullGenderIdToCreators < ActiveRecord::Migration[6.1]
  def change
    # NOT NULL解除
    change_column_null :creators, :gender_id, true
  end
end
