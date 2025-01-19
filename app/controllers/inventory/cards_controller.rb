class Inventory::CardsController < ApplicationController
  before_action :set_inventory_card, only: %i[ show edit update destroy ]

  # GET /inventory/cards or /inventory/cards.json
  def index
    @inventory_cards = Inventory::Card.all
  end

  # GET /inventory/cards/1 or /inventory/cards/1.json
  def show
  end

  # GET /inventory/cards/new
  def new
    @inventory_card = Inventory::Card.new
  end

  # GET /inventory/cards/1/edit
  def edit
  end

  # POST /inventory/cards or /inventory/cards.json
  def create
    @inventory_card = Inventory::Card.new(inventory_card_params)

    respond_to do |format|
      if @inventory_card.save
        format.html { redirect_to @inventory_card, notice: "Card was successfully created." }
        format.json { render :show, status: :created, location: @inventory_card }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @inventory_card.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /inventory/cards/1 or /inventory/cards/1.json
  def update
    respond_to do |format|
      if @inventory_card.update(inventory_card_params)
        format.html { redirect_to @inventory_card, notice: "Card was successfully updated." }
        format.json { render :show, status: :ok, location: @inventory_card }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @inventory_card.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /inventory/cards/1 or /inventory/cards/1.json
  def destroy
    @inventory_card.destroy!

    respond_to do |format|
      format.html { redirect_to inventory_cards_path, status: :see_other, notice: "Card was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_inventory_card
      @inventory_card = Inventory::Card.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def inventory_card_params
      params.fetch(:inventory_card, {})
    end
end
