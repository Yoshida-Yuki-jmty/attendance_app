# db/seeds.rb

def create_user(email, name)
  User.find_or_create_by!(email: email) do |u|
    u.name = name
    u.password = "password"
  end
end

users = [
  create_user("test1@example.com", "テスト1"),
  create_user("test2@example.com", "テスト2"),
  create_user("test3@example.com", "テスト3"),
  create_user("test4@example.com", "テスト4"),
  create_user("test5@example.com", "テスト5")
]

tz = Time.zone
month  = Date.current.beginning_of_month
today  = Date.current

users.each do |user|
  (month..today).each do |d|

    # テストデータ作成日までの勤怠情報を作成。
    att = user.attendances.find_or_initialize_by(work_on: d)
    att.breaktimes.destroy_all if att.persisted?

    start_at = tz.parse("#{d} 09:00")
    finish_at = tz.parse("#{d} 18:00")

    att.started_at  = start_at
    att.finished_at = (d == today ? nil : finish_at)
    att.save!

    att.breaktimes.create!(
      started_at: tz.parse("#{d} 12:00"),
      finished_at: tz.parse("#{d} 13:00")
    )
    att.breaktimes.create!(
      started_at: tz.parse("#{d} 15:15"),
      finished_at: tz.parse("#{d} 15:30")
    )
  end
end

puts "Seed completed: users=#{User.count}, attendances=#{Attendance.count}, breaktimes=#{Breaktime.count}"
