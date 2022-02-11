class CreateWorks < ActiveRecord::Migration[6.1]
  def change
    create_table :works do |t|
      t.date :date, null: false
      t.string :title
      t.text :description
      t.integer :scope_id, null: false
      t.references :creator, null: false, foreign_key: true

      t.timestamps
    end
  end
end
