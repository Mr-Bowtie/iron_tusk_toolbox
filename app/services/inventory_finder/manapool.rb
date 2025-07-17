module InventoryFinder
  class Manapool
    # Searches inventory using fields found in Manapool CSV's 
    #
    # @param row [CSV::Row]
    def self.find(row)
      Inventory::Card.where(
          scryfall_id: row["scryfall_id"],
          condition: Inventory::Card.map_condition(row["condition"]),
          foil: Inventory::Card.map_foil(row["foil"])
        ).to_a
    end
  end
end
