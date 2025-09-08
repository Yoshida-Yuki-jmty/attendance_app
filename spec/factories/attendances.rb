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
# spec/factories/attendances.rb
FactoryBot.define do
  factory :attendance do
    association :user

    # 既定は 当日 09:00-18:00
    work_date   { Date.current }
    started_at  { Time.zone.parse("#{work_date} 09:00") }
    finished_at { Time.zone.parse("#{work_date} 18:00") }

    trait :no_clock_out do
      finished_at { nil }
    end

    trait :with_breaks do
      # 休憩を2本デフォルトで作る
      after(:create) do |att|
        d = att.work_date
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

