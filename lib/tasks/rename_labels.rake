namespace :locations do
  desc "make label block locations start with # to make sorting work with other condition blocks"
  task rename_labels: :environment do
    Inventory::Location.all.each do |loc|
      split_label = loc.label.split("-")
      block_location = split_label.pop
      # block label ex: "NM01", want to swap the number and the condition to "01NM"
      block_number = block_location[2, 3]
      block_condition = block_location[0, 2]
      split_label << block_number + block_condition
      new_label = split_label.join("-")

      loc.update(label: new_label)
    end
  end
end
