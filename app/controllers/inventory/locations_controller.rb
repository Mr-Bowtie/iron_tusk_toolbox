class Inventory::LocationsController < ApplicationController
  # TODO: show a list of locations in order of position, ascending. eventually add drag and drop that adjusts the position. Or maybe just buttons that move it up or down
  def index
  end

  def new
    @inventory_location = Inventory::Location.new
  end

  
end
