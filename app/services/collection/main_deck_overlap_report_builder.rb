module Collection
  class MainDeckOverlapReportBuilder
    def self.call(main_decklist:, comparison_decklists:)
      new(main_decklist: main_decklist, comparison_decklists: comparison_decklists).call
    end

    def initialize(main_decklist:, comparison_decklists:)
      @main_decklist = main_decklist
      @comparison_decklists = comparison_decklists.to_a
    end

    def call
      overlapping_entries = build_overlapping_entries
      groups = build_groups(overlapping_entries)

      {
        report_type: "main_deck_overlap",
        main_decklist: decklist_snapshot(main_decklist, 0),
        comparison_decklists: comparison_decklists.each_with_index.map { |decklist, index| decklist_snapshot(decklist, index + 1) },
        decklists: selected_decklists.each_with_index.map { |decklist, index| decklist_snapshot(decklist, index) },
        summary: {
          selected_decklist_count: selected_decklists.length,
          unique_card_count: overlapping_entries.length,
          shared_card_count: overlapping_entries.length
        },
        groups: groups
      }
    end

    private

    attr_reader :main_decklist, :comparison_decklists

    def selected_decklists
      [ main_decklist, *comparison_decklists ]
    end

    def build_overlapping_entries
      entries = main_decklist.cards.each_with_object({}) do |card, hash|
        entry = hash[card.normalized_card_name] ||= {
          name: card.card_name,
          normalized_name: card.normalized_card_name,
          image_url: card.card_image_url,
          quantities: Hash.new(0),
          comparison_decklist_ids: []
        }
        entry[:image_url] ||= card.card_image_url
        entry[:quantities][main_decklist.id] += card.quantity
      end

      comparison_decklists.each do |decklist|
        decklist.cards.find_each do |card|
          entry = entries[card.normalized_card_name]
          next unless entry

          entry[:comparison_decklist_ids] << decklist.id unless entry[:comparison_decklist_ids].include?(decklist.id)
          entry[:quantities][decklist.id] += card.quantity
        end
      end

      entries.select { |_name, entry| entry[:comparison_decklist_ids].any? }
    end

    def build_groups(overlapping_entries)
      grouped = Hash.new { |hash, key| hash[key] = [] }

      overlapping_entries.each_value do |entry|
        comparison_ids = entry[:comparison_decklist_ids].sort
        grouped[comparison_ids] << {
          name: entry[:name],
          normalized_name: entry[:normalized_name],
          image_url: entry[:image_url],
          quantities: entry[:quantities].transform_keys(&:to_s)
        }
      end

      grouped.map do |comparison_ids, cards|
        {
          decklist_ids: [ main_decklist.id, *comparison_ids ],
          label: group_label(comparison_ids),
          cards: cards.sort_by { |card| card[:name].downcase }
        }
      end.sort_by { |group| [ -group[:decklist_ids].length, group[:label] ] }
    end

    def group_label(comparison_ids)
      names = comparison_ids.map { |id| comparison_decklist_by_id.fetch(id).name }
      "Also in #{names.join(' + ')}"
    end

    def comparison_decklist_by_id
      @comparison_decklist_by_id ||= comparison_decklists.index_by(&:id)
    end

    def decklist_snapshot(decklist, index)
      {
        id: decklist.id,
        name: decklist.name,
        position: index + 1
      }
    end
  end
end
