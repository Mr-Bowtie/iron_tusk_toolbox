require "csv"
require "fileutils"

module InventoryExporter
  class Backup < ApplicationService
    EXCLUDED_COLUMNS = %w[created_at updated_at].freeze

    def self.export_inventory_cards(output_path: nil, scope: Inventory::Card.all)
      new(scope: scope, output_path: output_path).export_inventory_cards
    end

    def initialize(scope:, output_path: nil)
      @scope = scope
      @output_path = output_path || default_path
    end

    def export_inventory_cards
      FileUtils.mkdir_p(File.dirname(output_path))

      CSV.open(output_path, "w", write_headers: true, headers: columns) do |csv|
        scope.find_each do |card|
          csv << columns.map { |column| card.public_send(column) }
        end
      end

      output_path
    end

    private

    attr_reader :scope, :output_path

    def columns
      @columns ||= Inventory::Card.column_names - EXCLUDED_COLUMNS
    end

    def default_path
      Rails.root.join("tmp", "inventory_cards_backup_#{Time.current.strftime("%Y%m%d%H%M%S")}.csv")
    end
  end
end
