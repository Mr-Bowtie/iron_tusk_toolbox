# == Schema Information
#
# Table name: card_metadata
#
#  id               :bigint           not null, primary key
#  booster          :boolean
#  cmc              :integer
#  collector_number :string
#  color_identity   :string           default([]), is an Array
#  colors           :string           default([]), is an Array
#  frame_effects    :string           default([]), is an Array
#  image_uris       :jsonb
#  keywords         :string           default([]), is an Array
#  layout           :string
#  legalities       :jsonb
#  mana_cost        :string
#  name             :string
#  oracle_text      :string
#  power            :string
#  prices           :jsonb
#  produced_mana    :string           default([]), is an Array
#  rarity           :string
#  set              :string
#  set_name         :string
#  toughness        :string
#  type_line        :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  scryfall_id      :string
#  tcgplayer_id     :integer
#
class CardMetadatum < ApplicationRecord
end
