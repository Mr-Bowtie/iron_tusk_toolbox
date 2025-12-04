class PdfService < ApplicationService
  # TODO: handle pulling different inventory types
  def self.generate_pull_sheet
    pull_items_scope = PullItem.joins(:inventory_location).includes(:inventory_location)
    tcgplayer_ri_pull = pull_items_scope.where("pull_items.data ->> 'source_format' = ?", "tcgplayer_ri_pull_sheet").exists?
    ordered_pull_items =
      if tcgplayer_ri_pull
        pull_items_scope.order(Arel.sql("(pull_items.data->>'csv_position')::int ASC NULLS LAST, pull_items.created_at ASC"))
      else
        pull_items_scope.order(Arel.sql("inventory_locations.label ASC, pull_items.data->>'name' ASC"))
      end

    pull_errors = PullError.all
    Prawn::Document.new.tap do |pdf|
      pdf.text "Pull Sheet", size: 24, style: :bold, align: :center
      pdf.move_down 20

      if ordered_pull_items.any?
        if tcgplayer_ri_pull
          ordered_by_position, unordered_items = ordered_pull_items.partition { |item| item.data["csv_position"].present? }

          if ordered_by_position.any?
            pdf.text "TCGPlayer RI (CSV order)", size: 18, align: :left
            render_pull_table(pdf, ordered_by_position)
            pdf.move_down 20
          end

          if unordered_items.any?
            pdf.text "Unordered / manual pulls (no CSV position)", size: 16, style: :bold, color: "AA0000"
            render_pull_table(pdf, unordered_items)
            pdf.move_down 20
          end
        else
          pull_items = ordered_pull_items
            .group_by { |item| [ item.data, item.inventory_type, item.inventory_location_id ] }
            .map do |(data, inventory_type, inventory_location_id), items|
              total_quantity = items.sum(&:quantity)

              PullItem.new(
                data: data,
                inventory_type: inventory_type,
                inventory_location_id: inventory_location_id,
                quantity: total_quantity
              )
            end

          pull_by_loc = pull_items.each_with_object({}) do |item, memo|
            if memo["#{item.inventory_location.label}"].nil?
              memo["#{item.inventory_location.label}"] = [ item ]
            else
              memo["#{item.inventory_location.label}"] << item
            end
          end

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

  def self.render_pull_table(pdf, items)
    data = [ [ "Location", "Quantity", "Name", "Number", "Set", "Foil", "Condition" ] ] +
      items.map do |card|
        [
          card.inventory_location.label,
          card.quantity,
          card.data["name"],
          card.data["number"],
          card.data["set_code"]&.upcase,
          card.data["foil"] ? "FOIL" : "Normal",
          card.data["condition"]
        ]
      end

    pdf.table(data, cell_style: { size: 8, inline_format: false }, column_widths: { 0 => 80, 2 => 200 }, header: true, row_colors: [ "F0F0F0", "FFFFFF" ], width: pdf.bounds.width) do |table|
      table.row(0).font_style = :bold
      table.column(0).font_style = :bold

      items.each_with_index do |card, index|
        next unless card.data["foil"]

        table.row(index + 1).background_color = "FFF6CC"
        table.row(index + 1).font_style = :bold
      end
    end
  end
end
