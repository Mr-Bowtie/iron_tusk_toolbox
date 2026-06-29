module Collection
  class DecklistReportBuilder
    def self.call(decklists:)
      new(decklists: decklists).call
    end

    def initialize(decklists:)
      @decklists = decklists.to_a
    end

    def call
      card_entries = build_card_entries
      groups = build_groups(card_entries)

      {
        decklists: decklists.each_with_index.map { |decklist, index| decklist_snapshot(decklist, index) },
        summary: {
          selected_decklist_count: decklists.length,
          unique_card_count: card_entries.length,
          shared_card_count: card_entries.count { |_name, entry| entry[:deck_quantities].length > 1 }
        },
        groups: groups
      }
    end

    private

    attr_reader :decklists

    def build_card_entries
      decklists.each_with_object({}) do |decklist, entries|
        decklist.cards.find_each do |card|
          entry = entries[card.normalized_card_name] ||= {
            name: card.card_name,
            normalized_name: card.normalized_card_name,
            image_url: card.card_image_url,
            deck_quantities: Hash.new(0)
          }
          entry[:image_url] ||= card.card_image_url
          entry[:deck_quantities][decklist.id] += card.quantity
        end
      end
    end

    def build_groups(card_entries)
      grouped = Hash.new { |hash, key| hash[key] = [] }

      card_entries.each_value do |entry|
        decklist_ids = entry[:deck_quantities].keys.sort
        grouped[decklist_ids] << {
          name: entry[:name],
          normalized_name: entry[:normalized_name],
          image_url: entry[:image_url],
          quantities: entry[:deck_quantities].transform_keys(&:to_s)
        }
      end

      grouped.map do |decklist_ids, cards|
        {
          decklist_ids: decklist_ids,
          label: group_label(decklist_ids),
          cards: cards.sort_by { |card| card[:name].downcase }
        }
      end.sort_by { |group| [ -group[:decklist_ids].length, group[:label] ] }
    end

    def group_label(decklist_ids)
      return "All selected decklists" if decklist_ids.length == decklists.length

      names = decklist_ids.map { |id| decklist_by_id.fetch(id).name }
      return "#{names.first} only" if names.one?

      names.join(" + ")
    end

    def decklist_by_id
      @decklist_by_id ||= decklists.index_by(&:id)
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
