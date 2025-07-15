class ScryfallBatchUpsertJob < ApplicationJob
  queue_as :default

  retry_on PG::ConnectionBad, wait: :exponentially_longer, attempts: 3

  around_perform do |job, block|
    ActiveRecord::Base.connection_pool.with_connection { block.call }
  ensure
    ActiveRecord::Base.connection_handler.clear_active_connections!
  end

  def perform(card_data:)
    update_columms = %i[
      tcgplayer_id
      name
      mana_cost
      cmc
      type_line
      oracle_text
      power
      toughness
      colors
      color_identity
      keywords
      legalities
      frame_effects
      layout
      produced_mana
      set
      set_name
      collector_number
      rarity
      booster
      front_image_uris
      back_image_uris
      image_uris
      prices
      updated_at
    ]
    CardMetadatum.import card_data, on_duplicate_key_update: { conflict_target: [ :scryfall_id ], columns: update_columms }
  end
end
