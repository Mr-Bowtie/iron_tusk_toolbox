module Inventory
  class StagingConversionService < ApplicationService
    def self.call(staged_cards:, location:, tcgplayer:)
      new(staged_cards: staged_cards, location: location, tcgplayer: tcgplayer).call
    end

    def initialize(staged_cards:, location:, tcgplayer:)
      @staged_cards = staged_cards
      @location = location
      @tcgplayer = ActiveModel::Type::Boolean.new.cast(tcgplayer)
    end

    def call
      ActiveRecord::Base.transaction do
        staged_cards.includes(:metadata).to_a.each do |staged_card|
          destination_card = Inventory::Card.find_by(
            scryfall_id: staged_card.scryfall_id,
            foil: staged_card.foil,
            condition: staged_card.condition,
            inventory_location_id: location.id,
            staged: false
          )

          if destination_card
            destination_card.update!(
              quantity: destination_card.quantity.to_i + staged_card.quantity.to_i,
              tcgplayer: tcgplayer
            )
            staged_card.destroy!
          else
            staged_card.update!(
              staged: false,
              inventory_location_id: location.id,
              tcgplayer: tcgplayer
            )
          end
        end
      end
    end

    private

    attr_reader :staged_cards, :location, :tcgplayer
  end
end
