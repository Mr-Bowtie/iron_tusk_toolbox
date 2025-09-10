module InventoryFinder
  class TcgplayerReimbursmentInvoice
    extend TcgplayerHelpers
    def self.find_from_csv(row)
      Inventory::Card.joins(:metadata, :inventory_location).where(
        tcgplayer: true,
        condition: Inventory::Card.map_condition(row["Condition"]),
        foil: row["Condition"].include?("Foil"),
        metadata: {
          collector_number: row["Number"],
          set_name: set_name_converter(row["Set Name"])
        }
      ).order("inventory_locations.label ASC").to_a
    end
  end
end
