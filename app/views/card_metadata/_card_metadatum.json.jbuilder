json.extract! card_metadatum, :id, :scryfall_id, :tcgplayer_id, :name, :mana_cost, :created_at, :updated_at
json.url card_metadatum_url(card_metadatum, format: :json)
