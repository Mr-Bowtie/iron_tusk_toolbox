class Inventory::BaseController < ApplicationController
  include Pagy::Backend

  # GET /inventory/
  def dashboard
    search_results = (Inventory::CardSearch.new(search_params).results)
    unless search_results.nil? 
      @pagy, @search_cards = pagy(search_results)
    end
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
    params.fetch(:search, {}).permit(
      :name,
      :set,
      :collector_number,
      :condition,
      :inventory_location_id
    )
    
  end
end
