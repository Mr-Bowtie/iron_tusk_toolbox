require "csv"

class CsvService
  # @param [CSV] import a csv of cards to add quantity for
  # @param [String] format the format of the import csv
  # @param [Integer] id of the location tag for the imported cards
  def self.add_from_import(import, format, location)
    case format
    when "manabox"
      CSV.foreach(import.path, headers: true) do |row|
        process_manabox_row_import(row, location)
      end
    end
  end

  # @param [CSV] import a csv of cards to remove quantity for
  # @param [String] format the format of the import csv
  def delete_from_import(import, format)
    # search for 
  end

  # @param [CSV::Row] row a singular row from an import csv to be processed
  # @param [Integer] id of the location tag for the imported card
  def self.process_manabox_row_import(row, location)
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
    card.tags.push(Tag.find(location))
    card.save
  end
end
