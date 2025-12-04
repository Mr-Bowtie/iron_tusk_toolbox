require "csv"

module InventoryImporter
  class ImportError < StandardError; end
  class Backup < Base
    EXCLUDED_COLUMNS = %w[created_at updated_at card_metadatum_id inventory_location_id].freeze

    def self.restore(file_path, wipe_existing: true)
      new(file_path: file_path, wipe_existing: wipe_existing).restore
    end

    def initialize(file_path:, wipe_existing: true)
      @file_path = file_path
      @wipe_existing = wipe_existing
      @boolean_type = ActiveModel::Type::Boolean.new
    end

    def restore
      ActiveRecord::Base.transaction do
        Inventory::Card.delete_all if wipe_existing
        import_rows
        reset_primary_key_sequence
      end
    end

    private

    attr_reader :file_path, :wipe_existing, :boolean_type

    def import_rows
      CSV.foreach(file_path, headers: true) do |row|
        next if row["scryfall_id"].nil?
        new_card = Inventory::Card.build(normalize_row(row.to_h))
        metadata = CardMetadatum.find_by(scryfall_id: row["scryfall_id"])
        raise ImportError, "No metadata found for scryfall_id: #{row["scryfall_id"]} for card from location: #{row["location_label"]}" unless metadata

        new_card.metadata = metadata
        location_label = row["location_label"] || "Lost and Found"
        location = Inventory::Location.find_or_create_by(label: location_label)
        new_card.inventory_location = location
        new_card.save!
      end
    end

    def normalize_row(attrs)
      filtered = attrs.slice(*columns)
      integer_columns.each { |column| filtered[column] = filtered[column].presence&.to_i }
      boolean_columns.each { |column| filtered[column] = boolean_type.cast(filtered[column]) }
      filtered
    end

    def integer_columns
      @integer_columns ||= %w[manabox_id quantity]
    end

    def boolean_columns
      @boolean_columns ||= %w[foil staged tcgplayer]
    end

    def columns
      @columns ||= (Inventory::Card.column_names - EXCLUDED_COLUMNS)
    end

    def reset_primary_key_sequence
      Inventory::Card.connection.reset_pk_sequence!(Inventory::Card.table_name)
    end
  end
end
