module InventoryFinder
  class Manapool
    # Searches inventory using fields found in Manapool CSV's
    #
    # @param row [CSV::Row]
    def self.find_from_csv(row)
      Inventory::Card.joins(:inventory_location).where(
          tcgplayer: false,
          scryfall_id: row["scryfall_id"],
          condition: Inventory::Card.map_condition(row["condition"]),
          foil: Inventory::Card.map_foil(row["foil"])
        ).order("inventory_locations.label ASC").to_a
    end

    def self.find_from_order_item(item)
      Inventory::Card.joins(:inventory_location).where(
              tcgplayer: false,
              scryfall_id: item["scryfall_id"],
              condition: Inventory::Card.map_condition(item["condition_id"]),
              foil: Inventory::Card.map_foil(item["finish_id"])
            ).order("inventory_locations.label ASC").to_a
    end
  end
end
