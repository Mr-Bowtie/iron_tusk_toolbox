class PdfService < ApplicationService
  # @param results [CsvService::PullResults]
  def self.generate_pull_sheet(pull_results)
    Prawn::Document.new.tap do |pdf|
      pdf.text "Pull Sheet", size: 24, style: :bold, align: :center
      pdf.move_down 20

      if pull_results.found_cards.any?
        pdf.text "Picked Cards", size: 18, style: :bold
        pdf.move_down 10

        data = [ [ "Location", "Quantity", "Name", "Condition", "Foil", "Set", "Number" ] ] +
              pull_results.found_cards.map do |card|
                [
                  card.location_label,
                  card.quantity,
                  card.name,
                  card.condition,
                  card.foil ? "Yes" : "No",
                  card.set_code,
                  card.number
                ]
              end

        pdf.table(data, header: true, row_colors: [ "F0F0F0", "FFFFFF" ], width: pdf.bounds.width)
        pdf.move_down 20
      else
        pdf.text "No cards found.", size: 12, style: :italic
        pdf.move_down 20
      end

      if pull_results.errors.any?
        pdf.text "Errors", size: 18, style: :bold, color: "FF0000"
        pdf.move_down 10

        pull_results.errors.each_with_index do |error, index|
          pdf.text "#{index + 1}. #{error.message}", size: 12, style: :bold
          pdf.text error.data.error_string, size: 10, indent_paragraphs: 20
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
