# == Schema Information
#
# Table name: pull_items
#
#  id                    :bigint           not null, primary key
#  data                  :jsonb
#  inventory_type        :integer
#  pulled                :boolean
#  quantity              :integer          not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  inventory_location_id :bigint           not null
#  pull_batches_id       :bigint
#
# Indexes
#
#  index_pull_items_on_inventory_location_id  (inventory_location_id)
#  index_pull_items_on_pull_batches_id        (pull_batches_id)
#
# Foreign Keys
#
#  fk_rails_...  (inventory_location_id => inventory_locations.id)
#
FactoryBot.define do
  factory :pull_item do
    
  end
end
