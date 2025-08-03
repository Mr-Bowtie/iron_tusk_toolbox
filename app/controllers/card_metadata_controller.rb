class CardMetadataController < ApplicationController
  before_action :set_card_metadatum, only: %i[ show edit update destroy ]

  def searc

  # GET /card_metadata or /card_metadata.json
  def index
    @card_metadata = CardMetadatum.all
  end

  # GET /card_metadata/1 or /card_metadata/1.json
  def show
  end

  # GET /card_metadata/new
  def new
    @card_metadatum = CardMetadatum.new
  end

  # GET /card_metadata/1/edit
  def edit
  end

  # POST /card_metadata or /card_metadata.json
  def create
    @card_metadatum = CardMetadatum.new(card_metadatum_params)

    respond_to do |format|
      if @card_metadatum.save
        format.html { redirect_to @card_metadatum, notice: "Card metadatum was successfully created." }
        format.json { render :show, status: :created, location: @card_metadatum }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @card_metadatum.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /card_metadata/1 or /card_metadata/1.json
  def update
    respond_to do |format|
      if @card_metadatum.update(card_metadatum_params)
        format.html { redirect_to @card_metadatum, notice: "Card metadatum was successfully updated." }
        format.json { render :show, status: :ok, location: @card_metadatum }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @card_metadatum.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /card_metadata/1 or /card_metadata/1.json
  def destroy
    @card_metadatum.destroy!

    respond_to do |format|
      format.html { redirect_to card_metadata_path, status: :see_other, notice: "Card metadatum was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_card_metadatum
      @card_metadatum = CardMetadatum.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def card_metadatum_params
      params.require(:card_metadatum).permit(:scryfall_id, :tcgplayer_id, :name, :mana_cost)
    end
end
