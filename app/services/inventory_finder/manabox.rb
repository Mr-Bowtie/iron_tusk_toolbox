module InventoryFinder
  class Manabox
    def self.find_from_csv(row)
     Inventory::Card.joins(:metadata, :inventory_location).where(
          tcgplayer: false,
          condition: Inventory::Card.map_condition(row["Condition"]),
          foil: Inventory::Card.map_foil(row["Foil"]),
          metadata: {
            scryfall_id: row["Scryfall ID"]
        }
        ).order("inventory_locations.label ASC").to_a
    end
  end
end
