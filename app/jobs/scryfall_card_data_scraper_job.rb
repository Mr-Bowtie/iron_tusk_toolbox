class ScryfallCardDataScraperJob < ApplicationJob
  queue_as :default

  def perform(card_data:, end_of_stream: false)
    front_image_uris = {}
    back_image_uris = {}

    unless card_data["card_faces"].nil?
      front_image_uris = card_data["card_faces"][0]["image_uris"]
      back_image_uris = card_data["card_faces"][1]["image_uris"]
    end

    CardMetadatum.upsert({
      scryfall_id: card_data["id"],
      tcgplayer_id: card_data["tcgplayer_id"],
      name: card_data["name"],
      mana_cost: card_data["mana_cost"],
      cmc: card_data["cmc"],
      type_line: card_data["type_line"],
      oracle_text: card_data["oracle_text"],
      power: card_data["power"],
      toughness: card_data["toughness"],
      colors: card_data["colors] || ["],
      color_identity: card_data["color_identity] || ["],
      keywords: card_data["keywords] || ["],
      legalities: card_data["legalities"] || {},
      frame_effects: card_data["frame_effects] || ["],
      layout: card_data["layout"],
      produced_mana: card_data["produced_mana] || ["],
      set: card_data["set"],
      set_name: card_data["set_name"],
      collector_number: card_data["collector_number"],
      rarity: card_data["rarity"],
      booster: card_data["booster"],
      front_image_uris: front_image_uris,
      back_image_uris: back_image_uris,
      image_uris: card_data["image_uris"] || {},
      prices: card_data["prices"] || {},
      created_at: Time.current,
      updated_at: Time.current
      },
      unique_by: :scryfall_id
    )

    ScryfallSyncService.sync_in_progress = false if end_of_stream

    # TODO: rescue and log errors with building metadata
  end
end
