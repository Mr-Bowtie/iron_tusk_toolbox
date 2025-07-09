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
class Inventory::Location < ApplicationRecord
  has_many :inventory_cards, class_name: "Inventory::Card", dependent: :nullify
  validates_uniqueness_of(:label)
end
