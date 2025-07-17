module Inventory
  class Deleter
    def self.delete_from_csv(file_path, format)
      raise "Only manabox supported for now" unless format == "manabox"

      messages = []
      CsvParser.parse(file_path).each do |row|
        card = Card.find_by(
          condition: row["Condition"],
          scryfall_id: row["Scryfall ID"],
          foil: row["Foil"].casecmp("foil").zero?
        )

        unless card
          messages << "no card in inventory with scryfall id: #{row["Scryfall ID"]}"
          next
        end

        qty = row["Quantity"].to_i
        if qty > card.quantity
          messages << "Overdelete on card #{card.id}: #{qty} out of #{card.quantity}"
          card.update(quantity: 0)
        else
          card.update(quantity: card.quantity - qty)
        end
      end
      messages
    end
  end
end

