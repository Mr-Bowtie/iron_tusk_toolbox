class Inventory::LocationMergesController < ApplicationController
  before_action :load_locations, only: :index
  before_action :set_location_merge, only: [ :show, :revert ]

  def index
    selection = selection_params
    @selected_source_id = selection[:source_location_id]
    @selected_destination_id = selection[:destination_location_id]
    @location_merges = Inventory::LocationMerge.includes(:source_location, :destination_location).recent_first
  end

  def show
    @source_cards = load_cards(@location_merge.inventory_card_ids)
    @destination_cards = load_cards(@location_merge.destination_card_ids)
    @gallery_cards = build_gallery_cards
  end

  def create
    source_location = Inventory::Location.find(location_merge_params[:source_location_id])
    destination_location = Inventory::Location.find(location_merge_params[:destination_location_id])

    merge = Inventory::LocationMergeService.new(
      source_location: source_location,
      destination_location: destination_location,
      user: current_user
    ).merge!

    redirect_to inventory_location_merge_path(merge), notice: "#{source_location.label} merged into #{destination_location.label}."
  rescue ActiveRecord::RecordNotFound, Inventory::LocationMergeService::MergeError => e
    redirect_to inventory_location_merges_path(
      location_merge: location_merge_params
    ), alert: e.message
  end

  def revert
    Inventory::LocationMergeService.revert!(location_merge: @location_merge)

    redirect_to inventory_location_merge_path(@location_merge), notice: "Reverted merge from #{@location_merge.source_location.label}."
  rescue ActiveRecord::RecordNotFound, Inventory::LocationMergeService::MergeError => e
    redirect_to inventory_location_merges_path, alert: e.message
  end

  private

  def load_locations
    @locations = Inventory::Location.order(:label)
  end

  def set_location_merge
    @location_merge = Inventory::LocationMerge.includes(:source_location, :destination_location).find(params[:id])
  end

  def load_cards(card_ids)
    ids = Array(card_ids).compact
    return Inventory::Card.none if ids.empty?

    Inventory::Card.includes(:metadata).where(id: ids)
  end

  def build_gallery_cards
    source_entries = @source_cards.map { |card| { card: card, origin: :source } }
    destination_entries = @destination_cards.map { |card| { card: card, origin: :destination } }

    (source_entries + destination_entries).sort_by { |entry| entry[:card].metadata&.name.to_s.downcase }
  end

  def location_merge_params
    params.require(:location_merge).permit(:source_location_id, :destination_location_id)
  end

  def selection_params
    {
      source_location_id: params.dig(:location_merge, :source_location_id)&.to_i || params[:source_location_id]&.to_i,
      destination_location_id: params.dig(:location_merge, :destination_location_id)&.to_i || params[:destination_location_id]&.to_i
    }
  end
end
