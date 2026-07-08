module InventoryImporter
  class Manabox < Base
    def self.prepare_rows(rows)
      grouped_rows = {}

      rows.each do |row|
        next if row["Name"].nil?

        key = [
          row["Scryfall ID"],
          Inventory::Card.map_foil(row["Foil"]),
          Inventory::Card.map_condition(row["Condition"])
        ]

        grouped_rows[key] ||= row.to_h.merge("Quantity" => 0)
        grouped_rows[key]["Quantity"] = grouped_rows[key]["Quantity"].to_i + row["Quantity"].to_i
      end

      grouped_rows.values
    end

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
