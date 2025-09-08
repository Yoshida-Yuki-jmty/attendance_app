class AddUniqueIndexOnOpenBreaktimes < ActiveRecord::Migration[6.1]
  def change
    # 「finished_at が NULL の行」に限って attendance_id をユニークにする
    add_index :breaktimes,
              :attendance_id,
              unique: true,
              where: "finished_at IS NULL",
              name: "index_breaktimes_on_attendance_id_open"
  end
end
