class CreateAttendances < ActiveRecord::Migration[6.1]
  def change
    create_table :attendances do |t|
      t.references :user, null: false, foreign_key: true
      t.date :work_date, null: false
      t.datetime :started_at
      t.datetime :finished_at

      t.timestamps
    end
    add_index :attendances, [:user_id, :work_date], unique: true
  end
end
