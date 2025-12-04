module InventoryFinder
  class TcgplayerReimbursmentInvoice
    extend TcgplayerHelpers
    def self.find_from_csv(row)
      metadata = {}
      # the collector number gets funky for list cards so we just dont add it. there should be only one list version of each card so the other filters should be fine.
      metadata[:collector_number] = row["Number"] unless row["Set Name"] == "The List Reprints"
      metadata[:set_name] = row["Card Name"].include?("Token") ? row["Set Name"] + " Tokens" : set_name_converter(row["Set Name"])
      
      Inventory::Card.joins(:metadata, :inventory_location).where(
        tcgplayer: true,
        condition: Inventory::Card.map_condition(row["Condition"]),
        foil: row["Condition"].include?("Foil"),
        metadata: metadata
      ).order("inventory_locations.label ASC").to_a
    end
  end
end
