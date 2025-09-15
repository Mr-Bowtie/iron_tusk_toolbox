# == Schema Information
#
# Table name: inventory_cards
#
#  id                    :bigint           not null, primary key
#  condition             :integer
#  foil                  :boolean
#  quantity              :integer
#  staged                :boolean
#  tcgplayer             :boolean
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  card_metadatum_id     :bigint
#  inventory_location_id :bigint
#  manabox_id            :integer
#  scryfall_id           :string
#
# Indexes
#
#  index_inventory_cards_on_card_metadatum_id                   (card_metadatum_id)
#  index_inventory_cards_on_inventory_location_id               (inventory_location_id)
#  index_inventory_cards_on_scryfall_id_and_foil_and_condition  (scryfall_id,foil,condition)
#
class Inventory::Card < ApplicationRecord
  belongs_to :metadata, class_name: "CardMetadatum", foreign_key: :card_metadatum_id
  has_many :card_tags, dependent: :nullify
  has_many :tags, through: :card_tags
  belongs_to :inventory_location, class_name: "Inventory::Location", optional: true

  enum :condition, [
    :near_mint,
    :lightly_played,
    :moderately_played,
    :heavily_played,
    :damaged
  ]

  def pull!(amount: 0, all_in_location: false)
    amount = all_in_location ? self.quantity : amount

    ActiveRecord::Base.transaction do
      PullItem.create!(
        inventory_type: "card",
        quantity: amount,
        inventory_location: inventory_location,
        data: {
          name: metadata.name,
          set_code: metadata.set,
          number: metadata.collector_number,
          scryfall_id: self.scryfall_id,
          foil: self.foil,
          condition: self.condition,
          card_metadatum_id: self.card_metadatum_id,
          tcgplayer: self.tcgplayer
          }
      )
    end

    self.quantity -= amount
    self.quantity.zero? ? self.destroy! : self.save!
  end

  # @param [String] condition
  #
  # this normalizes conditions from fields in csv's getting processed
  def self.map_condition(condition)
    noramilzed_condition = condition.split(" ").reject { |w| w == "Foil" }.join(" ")
    case noramilzed_condition
    when "mint", "NM", "Near Mint"
      "near_mint"
    when "LP", "Lightly Played", "near_mint"
      "lightly_played"
    when "excellent", "good", "MP", "Moderately Played"
      "moderately_played"
    when "light_played", "played", "HP", "Heavily Played"
      "heavily_played"
    when "poor", "DMG", "Damaged"
      "damaged"
    else

    end
  end

  # @param [String] foil
  #
  # maps foil input from field in ingested csv to internal boolean
  def self.map_foil(foil)
    case foil
    when "FO", /^.*Foil$/, "EF", "etched", "foil"
      true
    else
      false
    end
  end
end
