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
#  index_breaktimes_on_attendance_id  (attendance_id)
#
# Foreign Keys
#
#  fk_rails_...  (attendance_id => attendances.id)
#
FactoryBot.define do
  factory :breaktime do
    attendance { nil }
    started_at { "2025-09-05 17:26:33" }
    finished_at { "2025-09-05 17:26:33" }
  end
end
