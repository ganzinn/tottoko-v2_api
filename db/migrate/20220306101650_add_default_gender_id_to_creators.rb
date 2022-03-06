class AddDefaultGenderIdToCreators < ActiveRecord::Migration[6.1]
  def change
    # default指定なしは「nil」
    change_column_default :creators, :gender_id, from: nil, to: 3
  end
end
