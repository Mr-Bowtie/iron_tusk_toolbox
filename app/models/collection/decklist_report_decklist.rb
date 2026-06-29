# == Schema Information
#
# Table name: collection_decklist_report_decklists
#
#  id                 :bigint           not null, primary key
#  decklist_name      :string           not null
#  position           :integer          not null
#  source_filename    :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  decklist_id        :bigint           not null
#  decklist_report_id :bigint           not null
#
# Indexes
#
#  idx_on_decklist_report_id_e45ddd73cb                       (decklist_report_id)
#  index_collection_decklist_report_decklists_on_decklist_id  (decklist_id)
#  index_collection_report_decklists_on_report_and_decklist   (decklist_report_id,decklist_id)
#
# Foreign Keys
#
#  fk_rails_...  (decklist_id => collection_decklists.id)
#  fk_rails_...  (decklist_report_id => collection_decklist_reports.id)
#
class Collection::DecklistReportDecklist < ApplicationRecord
  self.table_name = "collection_decklist_report_decklists"

  belongs_to :decklist_report, class_name: "Collection::DecklistReport"
  belongs_to :decklist, class_name: "Collection::Decklist"

  validates :decklist_name, presence: true
  validates :source_filename, presence: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
