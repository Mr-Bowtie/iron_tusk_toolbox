# == Schema Information
#
# Table name: collection_decklists
#
#  id              :bigint           not null, primary key
#  card_count      :integer          default(0), not null
#  game_format     :string
#  metadata        :jsonb            not null
#  name            :string           not null
#  source_filename :string           not null
#  source_format   :string           default("manabox"), not null
#  uploaded_at     :datetime         not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_collection_decklists_on_name           (name)
#  index_collection_decklists_on_source_format  (source_format)
#
class Collection::Decklist < ApplicationRecord
  self.table_name = "collection_decklists"

  has_many :cards, class_name: "Collection::Card", dependent: :destroy
  has_many :decklist_report_decklists,
           class_name: "Collection::DecklistReportDecklist",
           dependent: :destroy
  has_many :decklist_reports, through: :decklist_report_decklists

  validates :name, presence: true
  validates :source_filename, presence: true
  validates :source_format, presence: true

  scope :recent_first, -> { order(created_at: :desc) }

  def self.name_from_filename(filename)
    File.basename(filename.to_s, File.extname(filename.to_s))
  end
end
