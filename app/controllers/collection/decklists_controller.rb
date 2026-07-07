class Collection::DecklistsController < ApplicationController
  def index
    @decklists = Collection::Decklist.includes(:cards).recent_first
    @decklist_reports = Collection::DecklistReport.recent_first.limit(10)
  end

  def new
    @decklist = Collection::Decklist.new
  end

  def show
    @decklist = Collection::Decklist.includes(:cards).find(params[:id])
    @cards = @decklist.cards.order(:normalized_card_name, :zone)
  end

  def create
    uploaded_file = decklist_params[:file] || decklist_params[:csv]
    raise ArgumentError, "Choose a ManaBox decklist file to upload." if uploaded_file.blank?

    decklist = Collection::Decklist.transaction do
      created_decklist = Collection::Decklist.create!(
        name: Collection::Decklist.name_from_filename(uploaded_file.original_filename),
        source_filename: uploaded_file.original_filename,
        source_format: "manabox",
        uploaded_at: Time.current
      )
      Collection::DecklistImporters::Manabox.call(file: uploaded_file, decklist: created_decklist)
      created_decklist
    end

    redirect_to collection_decklist_path(decklist), notice: "#{decklist.name} uploaded."
  rescue ActiveRecord::RecordInvalid, ArgumentError => e
    Monitoring::Reporter.capture_exception(
      e,
      message: "Decklist upload failed",
      tags: { component: "collection.decklists#create" },
      extra: { filename: uploaded_file&.original_filename }
    )
    redirect_to collection_decklists_path, alert: e.message
  end

  def destroy
    decklist = Collection::Decklist.find(params[:id])
    decklist.destroy!

    redirect_to collection_decklists_path, notice: "#{decklist.name} deleted."
  end

  private

  def decklist_params
    params.fetch(:decklist, {}).permit(:file, :csv)
  end
end
