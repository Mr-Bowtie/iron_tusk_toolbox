# == Schema Information
#
# Table name: collection_cards
#
#  id                   :bigint           not null, primary key
#  card_name            :string           not null
#  collector_number     :string
#  game_format          :string
#  normalized_card_name :string           not null
#  quantity             :integer          default(1), not null
#  raw_row              :jsonb            not null
#  set_code             :string
#  zone                 :string           default("mainboard"), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  decklist_id          :bigint           not null
#
# Indexes
#
#  index_collection_cards_on_decklist_id                           (decklist_id)
#  index_collection_cards_on_decklist_id_and_normalized_card_name  (decklist_id,normalized_card_name)
#  index_collection_cards_on_decklist_id_and_zone                  (decklist_id,zone)
#
# Foreign Keys
#
#  fk_rails_...  (decklist_id => collection_decklists.id)
#
class Collection::Card < ApplicationRecord
  self.table_name = "collection_cards"

  belongs_to :decklist, class_name: "Collection::Decklist"

  validates :card_name, presence: true
  validates :normalized_card_name, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :zone, presence: true

  before_validation :set_normalized_card_name
  before_validation :set_default_zone

  def self.normalize_name(name)
    name.to_s.strip.downcase
  end

  def card_image_url
    return if set_code.blank? || collector_number.blank?

    "https://api.scryfall.com/cards/#{ERB::Util.url_encode(set_code.downcase)}/#{ERB::Util.url_encode(collector_number)}?format=image&version=normal"
  end

  private

  def set_normalized_card_name
    self.normalized_card_name = self.class.normalize_name(card_name) if normalized_card_name.blank? && card_name.present?
  end

  def set_default_zone
    self.zone = "mainboard" if zone.blank?
  end
end
