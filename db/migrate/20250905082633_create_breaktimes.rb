class CreateBreaktimes < ActiveRecord::Migration[6.1]
  def change
    create_table :breaktimes do |t|
      t.references :attendance, null: false, foreign_key: true
      t.datetime :started_at
      t.datetime :finished_at

      t.timestamps
    end
  end
end
