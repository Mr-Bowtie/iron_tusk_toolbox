module Inventory
  class Puller
    SUPPORTED_FORMATS = {
      "manapool_csv" => InventoryFinder::Manapool
    }.freeze

    CardInfo = Struct.new(
      "CardInfo",
      :name,
      :condition,
      :foil,
      :location_label,
      :quantity,
      :set_code,
      :number,
      keyword_init: true
    ) do
      def error_string
        "#{name} #{set_code} #{number} #{condition} #{foil}"
      end
    end

    PullError = Struct.new("PullError", :message, :data, keyword_init: true)

    PullResults = Struct.new("PullResults", :found_cards, :errors) do
      def initialize(*)
        super
        self.found_cards ||= []
        self.errors ||= []
      end
    end

    # default to manapool_csv until other formats are spun up
    def self.process(file_path:, format:)
      finding_class = SUPPORTED_FORMATS[format]
      raise ArgumentError, "Unsupported format: #{format}" unless finding_class

      results = PullResults.new
      CsvParser.parse(file_path).each do |row|
        cards = finding_class.find(row)
        card_count = cards.sum(&:quantity)
        cards_to_pull = row["quantity"].to_i

        if cards.empty? || card_count == 0
          results.errors << PullError.new(
            message: "no card found in inventory",
            data: CardInfo.new(
              name: row["card_name"],
              condition: row["condition"],
              foil: row["foil"],
              quantity: row["quantity"],
              set_code: row["set"],
              number: row["number"]
            )
          )
          next
        end

        if card_count < cards_to_pull
          results.errors << PullError.new(
            message: "Insufficient inventory quantity. Requested: #{row['quantity']}, Found: #{card_count}",
            data: CardInfo.new(
              name: row["card_name"],
              condition: row["condition"],
              foil: row["foil"],
              quantity: row["quantity"],
              set_code: row["set"],
              number: row["number"]
            )
          )
          cards_to_pull = card_count
        end

        while cards_to_pull > 0
          active_card = cards.pop
          if active_card.quantity > cards_to_pull
            results.found_cards << CardInfo.new(
              name: active_card.metadata.name,
              condition: active_card.condition,
              foil: active_card.foil,
              location_label: active_card.inventory_location.label,
              quantity: cards_to_pull,
              set_code: active_card.metadata.set,
              number: active_card.metadata.collector_number
            )
            active_card.update(quantity: active_card.quantity - cards_to_pull)
            cards_to_pull = 0
          else
            results.found_cards << CardInfo.new(
              name: active_card.metadata.name,
              condition: active_card.condition,
              foil: active_card.foil,
              location_label: active_card.inventory_location.label,
              quantity: active_card.quantity,
              set_code: active_card.metadata.set,
              number: active_card.metadata.collector_number
            )
            cards_to_pull -= active_card.quantity
            active_card.delete
          end
        end
      end
      results
    end
  end
end
