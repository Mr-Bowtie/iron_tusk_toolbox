# == Schema Information
#
# Table name: tags
#
#  id         :bigint           not null, primary key
#  kind       :integer
#  value      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Tag < ApplicationRecord
  has_many :card_tags, dependent: :nullify
  has_many :cards, through: :card_tags

  enum :kind, [
    :location,
    :property
  ]
end
