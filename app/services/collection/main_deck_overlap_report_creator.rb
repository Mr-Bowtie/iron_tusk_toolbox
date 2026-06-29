module Collection
  class MainDeckOverlapReportCreator
    class ReportError < StandardError; end

    def self.call(main_decklist:, comparison_decklists:, name: nil)
      new(main_decklist: main_decklist, comparison_decklists: comparison_decklists, name: name).call
    end

    def initialize(main_decklist:, comparison_decklists:, name: nil)
      @main_decklist = main_decklist
      @comparison_decklists = comparison_decklists.to_a.uniq.reject { |decklist| decklist.id == main_decklist&.id }
      @name = name
    end

    def call
      raise ReportError, "Select a main deck to generate a focused overlap report." unless main_decklist
      raise ReportError, "Select at least one comparison decklist." if comparison_decklists.empty?

      snapshot = Collection::MainDeckOverlapReportBuilder.call(
        main_decklist: main_decklist,
        comparison_decklists: comparison_decklists
      )
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

        selected_decklists.each_with_index do |decklist, index|
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

    attr_reader :main_decklist, :comparison_decklists, :name

    def selected_decklists
      [ main_decklist, *comparison_decklists ]
    end

    def report_name
      name.presence || "#{main_decklist.name} overlap"
    end
  end
end
