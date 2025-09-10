class RenameWorkDateToWorkOnInAttendances < ActiveRecord::Migration[6.1]
  OLD_INDEX = :index_attendances_on_user_id_and_work_on
  NEW_INDEX = :index_attendances_on_user_id_and_work_on

  def up
    rename_column :attendances, :work_on, :work_on

    if index_name_exists?(:attendances, OLD_INDEX)
      rename_index :attendances, OLD_INDEX, NEW_INDEX
    else
      add_index :attendances, [:user_id, :work_on], unique: true, name: NEW_INDEX \
        unless index_exists?(:attendances, [:user_id, :work_on], unique: true, name: NEW_INDEX)
    end
  end

  def down
    if index_name_exists?(:attendances, NEW_INDEX)
      rename_index :attendances, NEW_INDEX, OLD_INDEX
    else
      add_index :attendances, [:user_id, :work_on], unique: true, name: OLD_INDEX \
        unless index_exists?(:attendances, [:user_id, :work_on], unique: true, name: OLD_INDEX)
    end

    rename_column :attendances, :work_on, :work_on
  end
end
