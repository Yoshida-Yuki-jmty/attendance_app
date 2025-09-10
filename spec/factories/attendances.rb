# == Schema Information
#
# Table name: attendances
#
#  id          :bigint           not null, primary key
#  finished_at :datetime
#  started_at  :datetime
#  work_on     :date             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :bigint           not null
#
# Indexes
#
#  index_attendances_on_user_id              (user_id)
#  index_attendances_on_user_id_and_work_on  (user_id,work_on) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :attendance do
    association :user

    # 既定は 当日 09:00-18:00
    work_on   { Date.current }
    started_at  { Time.zone.parse("#{work_on} 09:00") }
    finished_at { Time.zone.parse("#{work_on} 18:00") }

    trait :no_clock_out do
      finished_at { nil }
    end
  
    trait :finished do
      finished_at { Time.zone.parse("#{work_on} 18:00") }
    end


    trait :with_breaks do
      # 休憩を2本デフォルトで作る
      after(:create) do |att|
        d = att.work_on
        att.breaktimes.create!(
          started_at: Time.zone.parse("#{d} 12:00"),
          finished_at: Time.zone.parse("#{d} 13:00")
        )
        att.breaktimes.create!(
          started_at: Time.zone.parse("#{d} 15:15"),
          finished_at: Time.zone.parse("#{d} 15:30")
        )
      end
    end
  end
end

