# == Schema Information
#
# Table name: attendances
#
#  id          :bigint           not null, primary key
#  finished_at :datetime
#  started_at  :datetime
#  work_date   :date
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :bigint           not null
#
# Indexes
#
#  index_attendances_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :attendance do
    user { nil }
    work_date { "2025-09-05" }
    started_at { "2025-09-05 17:25:26" }
    finished_at { "2025-09-05 17:25:26" }
  end
end
