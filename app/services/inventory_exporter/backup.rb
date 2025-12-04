require "csv"
require "fileutils"

module InventoryExporter
  class Backup < ApplicationService
    EXCLUDED_COLUMNS = %w[created_at updated_at card_metadatum_id inventory_location_id].freeze

    def self.export_inventory_cards(output_path: nil, scope: Inventory::Card.all)
      new(scope: scope, output_path: output_path).export_inventory_cards
    end

    def initialize(scope:, output_path: nil)
      @scope = scope
      @output_path = output_path || default_path
    end

    def export_inventory_cards
      FileUtils.mkdir_p(File.dirname(output_path))

      CSV.open(output_path, "w", write_headers: true, headers: csv_columns) do |csv|
        scope.find_each do |card|
          data = table_columns.map { |column| card.public_send(column) }
          data << card.inventory_location.label
          csv << data
        end
      end

      output_path
    end

    private

    attr_reader :scope, :output_path

    def table_columns
      Inventory::Card.column_names - EXCLUDED_COLUMNS
    end

    def csv_columns
      @csv_columns ||= table_columns + ["location_label"]
    end

    def default_path
      Rails.root.join("tmp", "inventory_cards_backup_#{Time.current.strftime("%Y%m%d%H%M%S")}.csv")
    end
  end
end
