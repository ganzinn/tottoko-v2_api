class CreateComments < ActiveRecord::Migration[6.1]
  def change
    create_table :comments do |t|
      t.text :message, null: false
      t.references :work, null: false, foreign_key: true
      t.bigint :user_id, null: false

      t.timestamps
    end
  end
end
