# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   # encoding: utf-8
locations = %w[inventory bulk collection\ holding]
properties = %w[deck\ fodder sweeper]

locations.each do |loc|
  Tag.create(kind: 0, value: loc)
end

properties.each do |prop|
  Tag.create(kind: 1, value: prop)
end
