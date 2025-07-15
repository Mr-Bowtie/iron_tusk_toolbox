class Inventory::CardsController < ApplicationController
  before_action :set_staged_cards, only: %i[ staging clear_staging convert_to_inventory ]
  before_action :set_inventory_card, only: %i[ show edit update destroy ]

  # GET /inventory/cards or /inventory/cards.json
  def index
  end

  def pull_inventory
    if PullItem.any?
      flash.now[:alert] = "Process items ready to pull before adding more"
    else
      Inventory::Puller.process(file_path: params[:csv].path, format: params[:format])
    end

    redirect_to inventory_path
  end

  def generate_pull_sheet
    pdf_data = PdfService.generate_pull_sheet

    send_data pdf_data,
              filename: "it_pullsheet_#{Time.now.strftime('%y%m%d-%H%M')}.pdf",
              type: "application/pdf",
              disposition: "inline"
  end

  def process_import_for_staging
    CsvService.stage_import(params[:csv], "manabox")

    redirect_to inventory_cards_staging_path
  end

  def mark_items_pulled
    PullItem.delete_all
    PullError.delete_all

    redirect_to inventory_path
  end

  def revert_pull
    PullItem.all.each(&:undo!)
    PullError.delete_all

    redirect_to inventory_path
  end

  def staging
    @locations = Inventory::Location.all
  end

  def clear_staging
    @cards.delete_all

    redirect_to inventory_path
  end

  def convert_to_inventory
    location = nil
    if params[:new_location_label].length > 0
      location = Inventory::Location.create(label: params[:new_location_label])
      # If new location label was entered, clear any input from existing location selection
      params[:existing_location_id] = ""

    elsif params[:existing_location_id].length > 0
      location = Inventory::Location.find(params[:existing_location_id])
    end

    unless location.nil? || !location.valid?
      @cards.update_all staged: false, inventory_location_id: location.id
      redirect_to inventory_path, notice: "Staging successfully converted to live inventory"
    else
      flash.now[:alert] = "Select an existing inventory location or enter a new location label"
      render :staging, status: :unprocessable_entity
    end
  end

  # def upload_csv
  #   # add protections against param injection
  #   CsvService.add_from_import(params[:csv], "manabox", params[:card_location])
  #   redirect_to inventory_cards_path
  # end

  def delete_from_csv
    flash[:messages] = CsvService.delete_from_import(params[:csv], "manabox", params[:card_location])
    redirect_to inventory_cards_path
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
        format.html { redirect_back_or_to inventory_path(search: params[:search]), notice: "Card was successfully updated." }
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
      params.require(:inventory_card).permit(:quantity, :foil, :condition, :inventory_location_id)
    end

    def set_staged_cards
      @cards = Inventory::Card.joins(:metadata).where(staged: true).order("card_metadata.name ASC")
    end
end
