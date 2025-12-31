class PullItemsController < ApplicationController
  before_action :set_pull_item, only: %i[show edit update destroy]

  # GET /pull_items or /pull_items.json
  def index
    @pull_items = PullItem.all
  end

  # GET /pull_items/1 or /pull_items/1.json
  def show
  end

  # GET /pull_items/new
  def new
    @pull_item = PullItem.new
  end

  # GET /pull_items/1/edit
  def edit
  end

  # POST /pull_items or /pull_items.json
  def create
    @pull_item = PullItem.new(pull_item_params)

    respond_to do |format|
      if @pull_item.save
        format.html { redirect_to @pull_item, notice: "Pull item was successfully created." }
        format.json { render :show, status: :created, location: @pull_item }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @pull_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /pull_items/1 or /pull_items/1.json
  def update
    respond_to do |format|
      if @pull_item.update(pull_item_params)
        format.html { redirect_to @pull_item, notice: "Pull item was successfully updated." }
        format.json { render :show, status: :ok, location: @pull_item }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @pull_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /pull_items/1 or /pull_items/1.json
  def destroy
    @pull_item.destroy!

    respond_to do |format|
      format.html { redirect_to pull_items_path, status: :see_other, notice: "Pull item was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    def set_pull_item
      @pull_item = PullItem.find(params[:id])
    end

    def pull_item_params
      params.require(:pull_item).permit(
        :inventory_location_id,
        :pull_batches_id,
        :inventory_type,
        :quantity,
        :pulled,
        data: {}
      )
    end
end
