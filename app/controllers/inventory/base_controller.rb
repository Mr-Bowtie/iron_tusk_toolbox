class Inventory::BaseController < ApplicationController
  include Pagy::Backend

  # GET /inventory/
  def dashboard
    @pagy, @search_cards = pagy(Inventory::CardSearch.new(search_params).results)
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
  
  private

  def search_params
    params.require(:search).permit(
      :name,
      :set,
      :collector_number,
      :condition,
      :inventory_location_id
    )
    
  end
end
