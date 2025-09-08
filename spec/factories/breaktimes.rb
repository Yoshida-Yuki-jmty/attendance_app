# == Schema Information
#
# Table name: breaktimes
#
#  id            :bigint           not null, primary key
#  finished_at   :datetime
#  started_at    :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  attendance_id :bigint           not null
#
# Indexes
#
#  index_breaktimes_on_attendance_id       (attendance_id)
#  index_breaktimes_on_attendance_id_open  (attendance_id) UNIQUE WHERE (finished_at IS NULL)
#
# Foreign Keys
#
#  fk_rails_...  (attendance_id => attendances.id)
#
FactoryBot.define do
  factory :breaktime do
    association :attendance
    started_at  { Time.zone.parse("#{attendance.work_date} 12:00") }
    finished_at { Time.zone.parse("#{attendance.work_date} 12:45") }

    trait :open do
      finished_at { nil }
    end
  end
end
