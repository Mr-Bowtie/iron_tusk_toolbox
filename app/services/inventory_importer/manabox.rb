module InventoryImporter
  class Manabox < Base
    def import!
      Inventory::Card.create!(
        condition: Inventory::Card.map_condition(@row["Condition"]),
        scryfall_id: @row["Scryfall ID"],
        foil: Inventory::Card.map_foil(@row["Foil"]),
        quantity: @row["Quantity"].to_i,
        card_metadatum_id: CardMetadatum.find_by!(scryfall_id: @row["Scryfall ID"]).id,
        manabox_id: @row["ManaBox ID"].to_i,
        staged: true
      )
    end
  end
end

