require "csv"

class CsvService
  def add_from_import(import, type)
    case type
    when "manabox"
      CSV.foreach(import.path, headers: true) do |row|
      end
    else

    end
  end

  def delete_from_import(import, type)
  end

  def process_manabox_row(row)
    card = Inventory::Card.find_or_initialize_by(
      condition: row["condition"],
      scryfall_id: row["scryfall_id"],
      foil: row["foil"]
    )
    card.quantity ||= 0
    card.quantity += row["quantity"]
    card.metadata ||= CardMetadatum.where(scryfall_id: row["scryfall_id"])
    card.scryfall_id ||= row["scryfall_id"]
    card.manabox_id ||= row["manabox_id"]
    card.save
  end
end
