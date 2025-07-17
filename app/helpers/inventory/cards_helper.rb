module Inventory::CardsHelper
  def condition_class(condition)
    case condition
    when "near_mint"
      "has-text-primary"
    when "lightly_played"
      "has-text-info"
    when "moderately_played"
      "has-text-warning"
    when "heavily_played"
      "has-text-danger"
    when "damaged"
      "has-text-danger has-text-weight-bold is-underlined"
    end
  end

  def condition_decorator(condition)
    case condition
    when "near_mint"
      "NM"
    when "lightly_played"
      "LP"
    when "moderately_played"
      "MP"
    when "heavily_played"
      "HP"
    when "damaged"
      "DMG"
    end
  end
end
