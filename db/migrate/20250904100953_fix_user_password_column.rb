class FixUserPasswordColumn < ActiveRecord::Migration[6.1]
  def change
    remove_column :users, :encrypted_password, :string
    # has_secure_password 用のカラムを追加
    add_column :users, :password_digest, :string
  end
end
