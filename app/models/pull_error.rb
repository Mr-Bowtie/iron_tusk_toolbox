# == Schema Information
#
# Table name: pull_errors
#
#  id         :bigint           not null, primary key
#  data       :jsonb
#  item_type  :integer
#  message    :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class PullError < ApplicationRecord
  enum :item_type, [
    :card
  ]

  def data_string
    case item_type
    when "card"
      "#{data["name"]} #{data["set_code"]} #{data["number"]} #{data["condition"]} #{data["foil"]} #{data["tcgplayer"] ? 'tcgplayer' : ''}"
    end
  end
end 
