# == Schema Information
#
# Table name: pull_batches
#
#  id               :bigint           not null, primary key
#  completed        :boolean
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  assigned_user_id :bigint           not null
#
# Indexes
#
#  index_pull_batches_on_assigned_user_id  (assigned_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (assigned_user_id => users.id)
#
require "test_helper"

class PullBatchTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
