# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_01_25_211151) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "card_metadata", force: :cascade do |t|
    t.string "scryfall_id"
    t.integer "tcgplayer_id"
    t.string "name"
    t.string "mana_cost"
    t.integer "cmc"
    t.string "type_line"
    t.string "oracle_text"
    t.string "power"
    t.string "toughness"
    t.string "colors", default: [], array: true
    t.string "color_identity", default: [], array: true
    t.string "keywords", default: [], array: true
    t.jsonb "legalities", default: {}
    t.string "frame_effects", default: [], array: true
    t.string "layout"
    t.string "produced_mana", default: [], array: true
    t.string "set"
    t.string "set_name"
    t.string "collector_number"
    t.string "rarity"
    t.boolean "booster"
    t.jsonb "image_uris", default: {}
    t.jsonb "prices", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scryfall_id"], name: "index_card_metadata_on_scryfall_id", unique: true
  end

  create_table "card_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "card_id"
    t.bigint "tag_id"
    t.index ["card_id"], name: "index_card_tags_on_card_id"
    t.index ["tag_id"], name: "index_card_tags_on_tag_id"
  end

  create_table "inventory_cards", force: :cascade do |t|
    t.string "scryfall_id"
    t.integer "manabox_id"
    t.boolean "foil"
    t.integer "condition"
    t.integer "quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "card_metadatum_id"
    t.index ["card_metadatum_id"], name: "index_inventory_cards_on_card_metadatum_id"
    t.index ["scryfall_id", "foil", "condition"], name: "index_inventory_cards_on_scryfall_id_and_foil_and_condition", unique: true
  end

  create_table "tags", force: :cascade do |t|
    t.integer "kind"
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
