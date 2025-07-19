class PdfService < ApplicationService
  # TODO: handle pulling different inventory types
  def self.generate_pull_sheet
    pull_items = PullItem.joins(:inventory_location).all.order(Arel.sql("inventory_locations.label ASC, pull_items.data->>'name' ASC"))
    pull_by_loc = pull_items.each_with_object({}) do |item, memo|
      if memo["#{item.inventory_location.label}"].nil?
        memo["#{item.inventory_location.label}"] = [ item ]
      else
        memo["#{item.inventory_location.label}"] << item
      end
    end
    pull_errors = PullError.all
    Prawn::Document.new.tap do |pdf|
      pdf.text "Pull Sheet", size: 24, style: :bold, align: :center
      pdf.move_down 20

      if pull_by_loc.any?
        pull_by_loc.each do |loc, items|
          pdf.text "#{loc}", size: 18, align: :left
          data = [ [ "Quantity", "Name", "Number", "Set", "Foil", "Condition" ] ] +
                items.map do |card|
                  [
                    card.quantity,
                    card.data["name"],
                    card.data["number"],
                    card.data["set_code"].upcase,
                    card.data["foil"] ? "FOIL" : "Normal",
                    card.data["condition"]
                  ]
                end

          pdf.table(data, cell_style: { size: 8 }, column_widths: { 1 => 200 }, header: true, row_colors: [ "F0F0F0", "FFFFFF" ], width: pdf.bounds.width)
          pdf.move_down 20
        end
      else
        pdf.text "No cards found.", size: 12, style: :italic
        pdf.move_down 20
      end

      if pull_errors.any?
        pdf.text "Errors", size: 18, style: :bold, color: "FF0000"
        pdf.move_down 10

        pull_errors.each_with_index do |error, index|
          pdf.text "#{index + 1}. #{error.message}", size: 12, style: :bold
          pdf.text error.data_string, size: 10, indent_paragraphs: 20
          pdf.move_down 10
        end
      end
    end.render
  end

  # @param card [CsvService::CardInfo]
  def card_info(card)
    ""
  end
end
