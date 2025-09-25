class Inventory::BaseController < ApplicationController
  include Pagy::Backend

  # GET /inventory/
  def dashboard
    search_results = (Inventory::CardSearch.new(search_params).results)
    unless search_results.nil?
      @pagy, @search_cards = pagy(search_results)
    end
    @locations = Inventory::Location.all
    @inventory_card_count = Inventory::Card.sum(:quantity)
    @open_pull_batches = PullBatch.where(completed: false)
  end

  def convert_magic_sorter_to_manabox
    compressed_csv_data = CsvConverter::MagicSorterToManabox.convert_to_zip(params[:magic_sorter_csv])
    compressed_csv_data.rewind

    send_data compressed_csv_data.read,
              filename: "ms-to-mb-#{Time.now.strftime("%y%m%d-%I%M")}.zip",
              type: "application/zip",
              disposition: "inline"
  end

  private

  def search_params
    params.fetch(:search, {}).permit(
      :name,
      :set,
      :collector_number,
      :condition,
      :inventory_location_id
    )
  end

end
