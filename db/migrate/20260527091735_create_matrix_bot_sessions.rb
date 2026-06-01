class CreateMatrixBotSessions < ActiveRecord::Migration[7.2]
  def change
    create_table :matrix_bot_sessions do |t|
      t.text :access_token, null: false
      t.text :refresh_token
      t.datetime :expires_at
      t.string :device_id, default: "iron_tusk_alerts", null: false
      t.boolean :singleton, default: true, null: false

      t.timestamps
    end

    add_index :matrix_bot_sessions, :singleton, unique: true
  end
end
