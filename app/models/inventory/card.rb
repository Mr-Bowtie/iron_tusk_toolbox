class Inventory::Card < ApplicationRecord
  enum :condition, [
    :near_mint,
    :lightly_played,
    :moderately_played,
    :heavily_played,
    :damaged
  ]
end
