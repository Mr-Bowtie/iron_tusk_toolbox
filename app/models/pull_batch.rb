# == Schema Information
#
# Table name: pull_batches
#
#  id               :bigint           not null, primary key
#  completed        :boolean          default(FALSE)
#  label            :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  assigned_user_id :bigint           not null
#
# Indexes
#
#  index_pull_batches_on_assigned_user_id  (assigned_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (assigned_user_id => users.id)
#
class PullBatch < ApplicationRecord
  has_many :pull_items, dependent: :nullify, foreign_key: :pull_batches_id
  has_many :pull_errors, dependent: :delete_all, foreign_key: :pull_batches_id
  has_one :assigned_user, class_name: "User"
  before_destroy :revert_pull_items

  private
  def revert_pull_items
    pull_items.each { |pi| pi.undo! } unless completed
  end
end
