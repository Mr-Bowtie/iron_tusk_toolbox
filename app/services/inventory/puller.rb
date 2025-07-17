module Inventory
  class Puller
    SUPPORTED_FORMATS = {
      "manapool_csv" => InventoryFinder::Manapool
    }.freeze

    def self.process(file_path:, format:)
      finding_class = SUPPORTED_FORMATS[format]
      raise ArgumentError, "Unsupported format: #{format}" unless finding_class

      CsvParser.parse(file_path).each do |row|
        items = finding_class.find(row)
        item_count = items.sum(&:quantity)
        pull_count = row["quantity"].to_i

        if items.empty? || item_count == 0
           PullError.create!(
            message: "no Item found in inventory",
            item_type: "card",
            data: {
              name: row["card_name"],
              condition: row["condition"],
              foil: row["foil"],
              quantity: row["quantity"],
              set_code: row["set"],
              number: row["number"]
            }
          )
          next
        end

        if item_count < pull_count
           PullError.create!(
            message: "Insufficient inventory quantity. Requested: #{row['quantity']}, Found: #{pull_count}",
            item_type: "card",
            data: {
              name: row["card_name"],
              condition: row["condition"],
              foil: row["foil"],
              quantity: row["quantity"],
              set_code: row["set"],
              number: row["number"]
            }
          )
          pull_count = card_count
        end


        while pull_count > 0
          active_item = items.pop

          if active_item.quantity > pull_count
            active_item.pull!(amount: pull_count)
            pull_count = 0
          else
            pull_count -= active_item.quantity
            active_item.pull!(all_in_location: true)
          end
        end
      end
    end
  end
end
