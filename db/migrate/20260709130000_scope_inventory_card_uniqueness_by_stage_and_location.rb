class ScopeInventoryCardUniquenessByStageAndLocation < ActiveRecord::Migration[7.2]
  def up
    Inventory::Card.where(staged: nil).update_all(staged: false)

    change_column_default :inventory_cards, :staged, from: nil, to: false
    change_column_null :inventory_cards, :staged, false

    remove_index :inventory_cards, name: "index_inventory_cards_on_scryfall_id_and_foil_and_condition"

    add_index :inventory_cards,
              [ :scryfall_id, :foil, :condition ],
              unique: true,
              where: "staged = true",
              name: "index_inventory_cards_on_staged_card_key"

    add_index :inventory_cards,
              [ :scryfall_id, :foil, :condition, :inventory_location_id ],
              unique: true,
              where: "staged = false",
              name: "index_inventory_cards_on_live_card_key_and_location"
  end

  def down
    remove_index :inventory_cards, name: "index_inventory_cards_on_staged_card_key"
    remove_index :inventory_cards, name: "index_inventory_cards_on_live_card_key_and_location"

    change_column_null :inventory_cards, :staged, true
    change_column_default :inventory_cards, :staged, from: false, to: nil

    add_index :inventory_cards,
              [ :scryfall_id, :foil, :condition ],
              unique: true,
              name: "index_inventory_cards_on_scryfall_id_and_foil_and_condition"
  end
end
