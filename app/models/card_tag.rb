# == Schema Information
#
# Table name: card_tags
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  card_id    :bigint
#  tag_id     :bigint
#
# Indexes
#
#  index_card_tags_on_card_id  (card_id)
#  index_card_tags_on_tag_id   (tag_id)
#
class CardTag < ApplicationRecord
  belongs_to :card, class_name: "Inventory::Card"
  belongs_to :tag
end
