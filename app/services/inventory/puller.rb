module Inventory
  class Puller
    SUPPORTED_FORMATS = {
      "manapool_csv" => InventoryFinder::Manapool,
      "tcgplayer_pull_sheet" => InventoryFinder::Tcgplayer,
      "manabox_csv" => InventoryFinder::Manabox
    }.freeze

    def self.process(file_path:, format:)
      finding_class = SUPPORTED_FORMATS[format]
      raise ArgumentError, "Unsupported format: #{format}" unless finding_class

      CsvParser.parse(file_path).each do |row|
        # TODO: extract this to finding_class
        card_name = nil
        condition = nil
        foil = nil
        quantity = nil
        set_code = nil
        set_name = nil
        number = nil
        tcgplayer = false

        case format
        when "manapool_csv"
          card_name = row["card_name"]
          condition = row["condition"]
          foil = row["foil"]
          quantity = row["quantity"]
          set_code = row["set_code"]
          number = row["number"]
        when "tcgplayer_pull_sheet"
          next if row["Product Line"] == "Orders Contained in Pull Sheet:"
          card_name = row["Product Name"].sub(/\s*\(.*?\)\s*$/, "")
          condition = row["Condition"].sub(/\s*Foil$/, "")
          foil = row["Condition"].include?("Foil")
          quantity = row["Quantity"]
          set_name =  row["Set"]
          number = row["Number"]
          tcgplayer = true
        when "manabox_csv"
          card_name = row["Name"]
          condition = row["Condition"]
          foil = row["Foil"]
          quantity = row["Quantity"]
          set_code = row["Set Code"]
          number = row["Collector Number"]

        else
        end

        items = finding_class.find_from_csv(row)
        item_count = items.sum(&:quantity)
        pull_count = quantity.to_i

        if items.empty? || item_count == 0
           PullError.create!(
            message: "no Item found in inventory",
            item_type: "card",
            data: {
              name: card_name,
              condition: condition,
              foil: foil,
              quantity: quantity,
              set_code: set_code || set_name,
              number: number,
              tcgplayer: tcgplayer
            }
          )
          next
        end

        if item_count < pull_count
           PullError.create!(
            message: "Insufficient inventory quantity. Requested: #{quantity}, Found: #{item_count}",
            item_type: "card",
            data: {
              name: card_name,
              condition: condition,
              foil: foil,
              quantity: quantity,
              set_code: set_code || set_name,
              number: number,
              tcgplayer: tcgplayer
            }
          )
          pull_count = item_count
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

    def self.process_mp_orders
    end
  end
end
