class PullBatchesController < ApplicationController
  before_action :set_pull_batch, only: %i[ show edit update destroy ]

  # GET /pull_batches or /pull_batches.json
  def index
    @pull_batches = PullBatch.all
  end

  # GET /pull_batches/1 or /pull_batches/1.json
  def show
  end

  # GET /pull_batches/new
  def new
    @pull_batch = PullBatch.new
  end

  # GET /pull_batches/1/edit
  def edit
  end

  # POST /pull_batches or /pull_batches.json
  def create
    @pull_batch = PullBatch.new(pull_batch_params)

    respond_to do |format|
      if @pull_batch.save
        format.html { redirect_to @pull_batch, notice: "Pull batch was successfully created." }
        format.json { render :show, status: :created, location: @pull_batch }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @pull_batch.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /pull_batches/1 or /pull_batches/1.json
  def update
    respond_to do |format|
      if @pull_batch.update(pull_batch_params)
        format.html { redirect_to @pull_batch, notice: "Pull batch was successfully updated." }
        format.json { render :show, status: :ok, location: @pull_batch }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @pull_batch.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /pull_batches/1 or /pull_batches/1.json
  def destroy
    @pull_batch.destroy!

    respond_to do |format|
      format.html { redirect_to pull_batches_path, status: :see_other, notice: "Pull batch was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_pull_batch
      @pull_batch = PullBatch.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def pull_batch_params
      params.fetch(:pull_batch, {})
    end
end
