module Collection
  class DecklistReportCreator
    class ReportError < StandardError; end

    def self.call(decklists:, name: nil)
      new(decklists: decklists, name: name).call
    end

    def initialize(decklists:, name: nil)
      @decklists = decklists.to_a
      @name = name
    end

    def call
      raise ReportError, "Select at least two decklists to generate a report." if decklists.length < 2

      snapshot = Collection::DecklistReportBuilder.call(decklists: decklists)
      summary = snapshot.fetch(:summary)

      Collection::DecklistReport.transaction do
        report = Collection::DecklistReport.create!(
          name: report_name,
          selected_decklist_count: summary.fetch(:selected_decklist_count),
          unique_card_count: summary.fetch(:unique_card_count),
          shared_card_count: summary.fetch(:shared_card_count),
          snapshot: snapshot,
          generated_at: Time.current
        )

        decklists.each_with_index do |decklist, index|
          report.decklist_report_decklists.create!(
            decklist: decklist,
            decklist_name: decklist.name,
            source_filename: decklist.source_filename,
            position: index + 1
          )
        end

        report
      end
    end

    private

    attr_reader :decklists, :name

    def report_name
      name.presence || decklists.map(&:name).join(" + ")
    end
  end
end
