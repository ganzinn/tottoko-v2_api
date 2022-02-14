class CreateWorkTagRelations < ActiveRecord::Migration[6.1]
  def change
    create_table :work_tag_relations do |t|
      t.references :work, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end
  end
end
