# == Schema Information
#
# Table name: inventory_locations
#
#  id         :bigint           not null, primary key
#  label      :string
#  position   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require "test_helper"

class Inventory::LocationTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
