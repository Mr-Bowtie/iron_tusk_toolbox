# == Schema Information
#
# Table name: pull_errors
#
#  id              :bigint           not null, primary key
#  data            :jsonb
#  item_type       :integer
#  message         :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  pull_batches_id :bigint
#
# Indexes
#
#  index_pull_errors_on_pull_batches_id  (pull_batches_id)
#
require "test_helper"

class PullErrorTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
