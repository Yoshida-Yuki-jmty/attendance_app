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
require 'rails_helper'

RSpec.describe Breaktime, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
