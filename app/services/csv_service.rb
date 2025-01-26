require "csv"

class CsvService
  # @param [CSV] import :a csv of cards to add quantity for
  # @param [String] format :the format of the import csv
  # @param [Integer] location :id of the location tag for the imported cards
  def self.add_from_import(import, format, location)
    case format
    when "manabox"
      CSV.foreach(import.path, headers: true) do |row|
        process_manabox_row_import(row, location)
      end
    end
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
  def self.process_manabox_row_import(row, location)
    # TODO: switch to finding all cards matching, then filtering by location
    # INFO: we want to have seperate records for each card in each location
    card = Inventory::Card.find_or_initialize_by(
      condition: row["Condition"],
      scryfall_id: row["Scryfall ID"],
      foil: row["Foil"].downcase == "foil"
    )
    card.quantity ||= 0
    card.quantity += row["Quantity"].to_i
    card.metadata ||= CardMetadatum.where(scryfall_id: card.scryfall_id).first
    card.manabox_id ||= row["ManaBox ID"].to_i
    # add error handling for bad location id
    card.tags.push(Tag.find(location)) if card.tags.none? { |tag| id = location }
    card.save
  end
end
