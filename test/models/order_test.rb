# == Schema Information
#
# Table name: orders
#
#  id                :bigint           not null, primary key
#  fees              :integer
#  fulfillment_data  :jsonb
#  items             :jsonb
#  marketplace_label :string
#  net_earned        :integer
#  placed_at         :datetime
#  shipping_method   :string
#  shipping_paid     :integer
#  source            :integer
#  status            :integer
#  total_value       :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  marketplace_id    :string
#
require "test_helper"

class OrderTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
