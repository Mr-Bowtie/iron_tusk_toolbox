require "csv"

module Collection
  module DecklistImporters
    class Manabox
      MAYBEBOARD_ZONES = %w[maybeboard maybe considering planning].freeze
      SECTION_ZONES = {
        "commander" => "commander",
        "deck" => "mainboard",
        "main" => "mainboard",
        "mainboard" => "mainboard",
        "sideboard" => "sideboard",
        "maybeboard" => "maybeboard",
        "maybe" => "maybeboard",
        "considering" => "maybeboard",
        "planning" => "maybeboard"
      }.freeze

      def self.call(file:, decklist:)
        new(file: file, decklist: decklist).call
      end

      def initialize(file:, decklist:)
        @file = file
        @decklist = decklist
      end

      def call
        grouped_rows = Hash.new { |hash, key| hash[key] = { quantity: 0, raw_rows: [] } }

        if csv_export?(file_contents)
          collect_csv_rows(grouped_rows)
        else
          collect_text_rows(grouped_rows)
        end

        decklist.cards.delete_all
        grouped_rows.each do |(normalized_name, zone), attributes|
          decklist.cards.create!(
            card_name: attributes[:card_name],
            normalized_card_name: normalized_name,
            quantity: attributes[:quantity],
            zone: zone,
            set_code: attributes[:set_code],
            collector_number: attributes[:collector_number],
            raw_row: { rows: attributes[:raw_rows] }
          )
        end

        decklist.update!(card_count: decklist.cards.sum(:quantity))
        decklist
      end

      private

      attr_reader :file, :decklist

      def collect_csv_rows(grouped_rows)
        CSV.parse(file_contents, headers: true) do |row|
          card_name = row["Name"].to_s.strip
          next if card_name.blank?

          zone = normalize_zone(row["Board"] || row["Zone"] || row["Section"])
          quantity = row["Quantity"].to_i
          collect_card(
            grouped_rows,
            card_name: card_name,
            quantity: quantity,
            zone: zone,
            set_code: first_present(row, "Set code", "Set Code", "Set", "Edition"),
            collector_number: first_present(row, "Collector number", "Collector Number", "Card Number", "Number"),
            raw_row: row.to_h
          )
        end
      end

      def collect_text_rows(grouped_rows)
        current_zone = "mainboard"

        file_contents.each_line do |line|
          stripped_line = line.strip
          next if stripped_line.blank?

          if stripped_line.start_with?("//")
            current_zone = normalize_zone(stripped_line.delete_prefix("//"))
            next
          end

          parsed_card = parse_text_card_line(stripped_line)
          next unless parsed_card

          collect_card(
            grouped_rows,
            card_name: parsed_card.fetch(:card_name),
            quantity: parsed_card.fetch(:quantity),
            zone: current_zone,
            set_code: parsed_card.fetch(:set_code),
            collector_number: parsed_card.fetch(:collector_number),
            raw_row: { "line" => stripped_line }
          )
        end
      end

      def collect_card(grouped_rows, card_name:, quantity:, zone:, raw_row:, set_code: nil, collector_number: nil)
        return if maybeboard?(zone)
        return unless quantity.positive?

        normalized_name = Collection::Card.normalize_name(card_name)
        key = [ normalized_name, zone ]
        grouped_rows[key][:card_name] ||= card_name
        grouped_rows[key][:set_code] ||= set_code.to_s.strip.presence
        grouped_rows[key][:collector_number] ||= collector_number.to_s.strip.presence
        grouped_rows[key][:quantity] += quantity
        grouped_rows[key][:raw_rows] << raw_row
      end

      def parse_text_card_line(line)
        normalized_line = line.sub(/\s+\*F\*\z/i, "")
        match = normalized_line.match(/\A(?<quantity>\d+)\s+(?<card_name>.+?)\s+\((?<set_code>[^)]+)\)\s+(?<collector_number>\S+)\z/)
        return unless match

        {
          quantity: match[:quantity].to_i,
          card_name: match[:card_name].strip,
          set_code: match[:set_code].strip,
          collector_number: match[:collector_number].strip
        }
      end

      def first_present(row, *headers)
        headers.each do |header|
          value = row[header].to_s.strip
          return value if value.present?
        end

        nil
      end

      def file_contents
        @file_contents ||= if file.respond_to?(:read)
          file.rewind if file.respond_to?(:rewind)
          file.read
        else
          File.read(file)
        end
      end

      def csv_export?(contents)
        first_line = contents.each_line.find { |line| line.strip.present? }.to_s
        headers = CSV.parse_line(first_line)
        headers&.include?("Name") && headers&.include?("Quantity")
      rescue CSV::MalformedCSVError
        false
      end

      def normalize_zone(value)
        normalized = value.to_s.strip.downcase
        SECTION_ZONES.fetch(normalized, normalized.presence || "mainboard")
      end

      def maybeboard?(zone)
        MAYBEBOARD_ZONES.include?(zone)
      end
    end
  end
end
