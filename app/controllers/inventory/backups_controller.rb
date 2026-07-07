module Inventory
  class BackupsController < ApplicationController
    def manage
    end

    def create
      backup = InventoryExporter::Backup.export_inventory_cards

      send_data backup.read,
                filename: "inventory_backup_#{Time.now.strftime("%y%m%d-%I%M")}.csv",
                type: "text/csv",
                disposition: "attachment"
      #
      # redirect_to inventory_backups_manage_path, alert: "Backup exported"
    end

    def restore
      file = backup_params[:file]

      if file.blank?
        redirect_to inventory_backups_manage_path, alert: "Please choose a backup file to restore."
        return
      end

      InventoryImporter::Backup.restore(file.path)

      redirect_to inventory_path, notice: "Inventory restored from backup."
    rescue StandardError => e
      Monitoring::Reporter.capture_exception(
        e,
        message: "Inventory restore failed",
        tags: { component: "inventory.backups#restore" },
        extra: { filename: file&.original_filename }
      )
      redirect_to inventory_backups_manage_path, alert: "Restore failed: #{e.message}"
    end

    private

    def backup_params
      params.fetch(:backup, ActionController::Parameters.new).permit(:file)
    end
  end
end
