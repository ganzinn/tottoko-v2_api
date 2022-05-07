class ChangeDataRefreshJtiToUsers < ActiveRecord::Migration[6.1]
  def change
    change_column :users, :refresh_jti, :text
  end
end
