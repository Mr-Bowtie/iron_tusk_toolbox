class Collection::DecklistReportsController < ApplicationController
  def index
    @decklist_reports = Collection::DecklistReport.recent_first
  end

  def show
    @decklist_report = Collection::DecklistReport.find(params[:id])
    @snapshot = @decklist_report.snapshot
  end

  def create
    report = create_report

    redirect_to collection_decklist_report_path(report), notice: "Decklist report generated."
  rescue Collection::DecklistReportCreator::ReportError, Collection::MainDeckOverlapReportCreator::ReportError => e
    redirect_to collection_decklists_path, alert: e.message
  end

  def destroy
    report = Collection::DecklistReport.find(params[:id])
    report.destroy!

    redirect_to collection_decklist_reports_path, notice: "#{report.name} deleted."
  end

  private

  def selected_decklist_ids
    params.fetch(:decklist_report, {}).fetch(:decklist_ids, []).reject(&:blank?)
  end

  def create_report
    return create_main_deck_overlap_report if main_deck_overlap_report?

    decklists = Collection::Decklist.where(id: selected_decklist_ids).order(:name).to_a
    Collection::DecklistReportCreator.call(decklists: decklists)
  end

  def create_main_deck_overlap_report
    Collection::MainDeckOverlapReportCreator.call(
      main_decklist: selected_main_decklist,
      comparison_decklists: selected_comparison_decklists
    )
  end

  def main_deck_overlap_report?
    params.fetch(:decklist_report, {}).fetch(:report_type, nil) == "main_deck_overlap"
  end

  def selected_main_decklist
    Collection::Decklist.find_by(id: params.fetch(:decklist_report, {}).fetch(:main_decklist_id, nil))
  end

  def selected_comparison_decklists
    Collection::Decklist.where(id: selected_comparison_decklist_ids).order(:name).to_a
  end

  def selected_comparison_decklist_ids
    params.fetch(:decklist_report, {}).fetch(:comparison_decklist_ids, []).reject(&:blank?)
  end
end
