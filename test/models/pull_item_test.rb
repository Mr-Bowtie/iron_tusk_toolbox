# == Schema Information
#
# Table name: pull_items
#
#  id                    :bigint           not null, primary key
#  data                  :jsonb
#  inventory_type        :integer
#  quantity              :integer          not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  inventory_location_id :bigint           not null
#
# Indexes
#
#  index_pull_items_on_inventory_location_id  (inventory_location_id)
#
# Foreign Keys
#
#  fk_rails_...  (inventory_location_id => inventory_locations.id)
#
require "test_helper"

class PullItemTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
