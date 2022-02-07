class CreateFamilies < ActiveRecord::Migration[6.1]
  def change
    create_table :families do |t|
      t.references :user, null: false, foreign_key: true
      t.references :creator, null: false, foreign_key: true
      t.integer :relation_id, null: false

      t.timestamps
    end
  end
end
