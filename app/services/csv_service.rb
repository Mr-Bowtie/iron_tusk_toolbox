require "csv"

class CsvService < ApplicationService
  # @param [CSV] import :a csv of cards to add quantity for
  # @param [String] format :the format of the import csv
  # @param [Integer] location :id of the location tag for the imported cards
  def self.stage_import(import, format)
    process_streamed_csv(import.path, format: format)
  end

  # @param [CSV] import :a csv of cards to remove quantity for
  # @param [String] format :the format of the import csv
  # @param [Integer] location :id of the location tag for the cards to be deleted
  # @return [Array<String>] messages :error or operational messages generated while removing inventory
  #
  # this removes quantity from inventory items.
  # items with 0 quantity are remain to track history of stock.
  def self.delete_from_import(import, format, location)
    case format
    when "manabox"
      messages = []
      CSV.foreach(import.path, headers: true) do |row|
        card = Inventory::Card.find_by(
          condition: row["Condition"],
          scryfall_id: row["Scryfall ID"],
          foil: row["Foil"].downcase == "foil"
        )

        if card.nil?
          messages.push("no card in inventory with scryfall id: #{row["Scryfall ID"]}, condition #{row["Condition"]}, foil #{row["Foil"].downcase == 'foil'}")
          next
        end

        if row["Quantity"].to_i > card.quantity
          messages.push("Overdelete on card id #{card.id}: #{row['Quantity']} out of #{card.quantity}")
          card.quantity = 0
        else
        card.quantity -= row["Quantity"].to_i
        end

        card.save
      end
      messages
    end
  end

  # @param [CSV::Row] row a singular row from an import csv to be processed
  # @param [Integer] id of the location tag for the imported card
  def self.process_manabox_row_import(row)
    # INFO: we want to have seperate records for each card in each location
    Inventory::Card.create(
      condition: Inventory::Card.map_condition(row["Condition"]),
      scryfall_id: row["Scryfall ID"],
      foil: row["Foil"].downcase == "foil",
      quantity: row["Quantity"].to_i,
      card_metadatum_id: CardMetadatum.where(scryfall_id: row["Scryfall ID"]).first.id,
      manabox_id: row["ManaBox ID"].to_i,
      staged: true,
      # inventory_location_id: Inventory::Location.find_or_create_by(label: "Staging").id
    )
  end

  PickedCard = Struct.new(
        "PickedCard",
        :name,
        :condition,
        :foil,
        :location_label,
        :quantity,
        keyword_init: true
      )

  PullError = Struct.new(
    "PullError",
    :message,
    :data,
    keyword_init: true
  )

  PullResults = Struct.new("PullResults", :found_cards, :errors) do
    def initialize(*)
      super
      self.found_cards ||= []
      self.errors ||= []
    end
  end

  # TODO: Refactor the hell out of this

  # @param [String] file_path location of manapool pull sheet generated with cli tool
  #
  # @return [CsvService::PullResults]
  def self.process_manapool_pull(file_path)
    results = PullResults.new
    CSV.foreach(file_path, headers: true) do |row|
      # TODO: sort by location

      # Find all cards in all locations that match the current card datetime
      cards = Inventory::Card.where(
        scryfall_id: row["scryfall_id"],
        condition: Inventory::Card.map_condition(row["condition"]),
        foil: Inventory::Card.map_foil(row["foil"])
      ).to_a

      # Log when a card is not found in inventory, process next card
      if cards.empty?
        results.errors << PullError.new(message: "no card found in inventory", data: row)
        next
      end

      # Check to see if there is enough quantity in inventory to satisfy the pull sheet, if not log error and set pull quantity to total in stock
      card_count = cards&.reduce(0) { |memo, card| memo += card.quantity }
      cards_to_pull = row["quantity"].to_i
      if card_count < cards_to_pull
        results[:errors] << PullError.new(message: "Insufficient inventory quantity. Requested: #{row[:quantity]}, Found in inventory: #{cards.length}")
        cards_to_pull = card_count
      end


      # Iterate over found cards and built pull list
      while cards_to_pull != 0
        active_card = cards.pop

        # if card quantity greater than cards to pull, reduce inventory quantity by pull quantity
        # push into found cards with pull quantity, set pull to 0

        if active_card.quantity >= cards_to_pull
          pulled_cards = PickedCard.new(
            name: active_card.metadata.name,
            condition: active_card.condition,
            foil: active_card.foil,
            location_label: active_card.inventory_location.label,
            quantity: cards_to_pull
          )
          results.found_cards << pulled_cards
          active_card.update(quantity: active_card.quantity - cards_to_pull)
          cards_to_pull = 0

        else
          pulled_cards = PickedCard.new(
            name: active_card.metadata.name,
            condition: active_card.condition,
            foil: active_card.foil,
            location_label: active_card.inventory_location.label,
            quantity: active_card.quantity
          )

          results.found_cards << pulled_cards
          cards_to_pull -= active_card.quantity
          active_card.delete
        end

      end
    end
    results
  end

  def self.process_streamed_csv(file_path, format: "manabox", thread_count: 4, batch_size: 1_000)
    work_queue = Queue.new
    result_queue = Queue.new
    threads = []

    # Worker threads
    thread_count.times do
      threads << Thread.new do
        while (batch = work_queue.pop) != :END
          processed = nil
          case format
          when "manabox"
            processed = []
            batch.each do |row|
              process_manabox_row_import(row)
            end
          end

          result_queue << processed
        end
      end
    end

    # Read file in batches and feed the queue
    batch = []
    CSV.foreach(file_path, headers: true) do |row|
      batch << row
      if batch.size >= batch_size
        work_queue << batch
        batch = []
      end
    end
    work_queue << batch unless batch.empty?

    # Signal threads to finish
    thread_count.times { work_queue << :END }
    threads.each(&:join)

    # Collect results
    results = []
    results.concat(result_queue.pop) until result_queue.empty?
    results
  end
end
