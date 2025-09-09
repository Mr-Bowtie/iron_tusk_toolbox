require "zip"

module CsvConverter
 class MagicSorterToManabox
  def self.convert_to_zip(csv)
    sorting_locations = {}
    output_csv_base = Time.now.strftime("%y%m%d")

    CsvParser.parse(csv.path).each do |row|
      # skip any card processing errors
      next if row["title"] == "Not found"
      # separate out locations
      if sorting_locations.keys.include?(row["position"])
        sorting_locations[row["position"]] << row
      else
      sorting_locations[row["position"]] = [ row ]
      end
    end

    # create zip file
    zip_file = Zip::OutputStream.write_buffer do |zip|
      # create csv entry for each location in the sorter csv
      sorting_locations.keys.each do |location|
        file_name = "#{output_csv_base}-#{Time.now.strftime("%I%M-%6N")}-#{location}.csv"
        sorting_data = sorting_locations[location]
        data_rows = []

        # create manabox rows from sorting row data
        sorting_data.each do |sort_row|
          row_data = {}
          row_data["Scryfall ID"] = sort_row["scryfall_id"]
          row_data["Foil"] = sort_row["foil"] == "0" ? "normal" : "foil"
          row_data["condition"] = map_condition(sort_row["condition"])
          data_rows << row_data
        end

        # Build CSV from new rows
        csv_data = CSV.generate(headers: true) do |csv|
          csv << data_rows.first.keys
          data_rows.each { |dr| csv << dr }
        end

        # Add new CSV to Zip file
        zip.put_next_entry(file_name)
        zip.write csv_data
      end
    end

    zip_file
  end

  def self.map_condition(condition)
    case condition
    when "NM"
      "mint"
    when "LP"
      "near_mint"
    when "MP"
      "excellent"
    when "HP"
      "played"
    when "DMG"
      "poor"
    end
  end
 end
end
