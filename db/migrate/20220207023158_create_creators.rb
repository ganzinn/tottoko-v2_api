class CreateCreators < ActiveRecord::Migration[6.1]
  def change
    create_table :creators do |t|
      t.string :name, null: false
      t.date :date_of_birth, null: false
      t.integer :gender_id, null: false

      t.timestamps
    end
  end
end
