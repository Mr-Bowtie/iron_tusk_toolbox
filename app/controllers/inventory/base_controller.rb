class Inventory::BaseController < ApplicationController

  # GET /inventory/
  def dashboard
    @locations = Inventory::Location.all
  end
end
