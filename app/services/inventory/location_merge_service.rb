module Inventory
  class LocationMergeService < ApplicationService
    class MergeError < StandardError; end

    attr_reader :source_location, :destination_location, :user

    def initialize(source_location:, destination_location:, user: nil)
      @source_location = source_location
      @destination_location = destination_location
      @user = user
    end

    def merge!
      raise MergeError, "Please select different source and destination locations." if same_location?

      Inventory::LocationMerge.transaction do
        card_ids = Inventory::Card.where(inventory_location: source_location).pluck(:id)
        destination_snapshot_ids = Inventory::Card.where(inventory_location: destination_location).pluck(:id)

        raise MergeError, "#{source_location.label} is empty." if card_ids.empty?

        Inventory::Card.where(id: card_ids).update_all(inventory_location_id: destination_location.id)
        Inventory::LocationMerge.create!(
          source_location: source_location,
          destination_location: destination_location,
          inventory_card_ids: card_ids,
          destination_card_ids: destination_snapshot_ids
        )
      end
    end

    def self.revert!(location_merge:)
      raise MergeError, "Merge has already been reverted." if location_merge.reverted?

      Inventory::LocationMerge.transaction do
        card_ids = Inventory::Card.where(
          id: location_merge.inventory_card_ids,
          inventory_location_id: location_merge.destination_location_id
        ).pluck(:id)

        Inventory::Card.where(id: card_ids).update_all(inventory_location_id: location_merge.source_location_id) if card_ids.any?

        location_merge.update!(
          reverted_inventory_card_ids: card_ids,
          reverted_at: Time.current
        )

        location_merge
      end
    end

    private

    def same_location?
      source_location == destination_location
    end
  end
end
