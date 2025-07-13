class Inventory::BaseController < ApplicationController

  # GET /inventory/
  def dashboard
    @locations = Inventory::Location.all
    @inventory_card_count = Inventory::Card.sum(:quantity)
    @pull_items = PullItem.all.each_with_object({}) do |item, memo|
      if memo[item.inventory_type].nil?
        memo[item.inventory_type] = item.quantity
      else
        memo[item.inventory_type] += item.quantity
      end
    end
  end
end
