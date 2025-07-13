module Inventory
  class CardSearch
    attr_reader :params, :relation

    def initialize(params = {}, relation: Inventory::Card.includes(:metadata, :inventory_location).references(:metadata, :inventory_location))
      @params = params
      @relation = relation
    end

    def results
      scope = relation

      if params[:name].present?
        scope = scope.where("LOWER(card_metadata.name) LIKE ?", "%#{params[:name].downcase}%")
      end

      if params[:set].present?
        scope = scope.where("LOWER(card_metadata.set) LIKE ?", "%#{params[:set].downcase}%")
      end

      if params[:collector_number].present?
        scope = scope.where(card_metadata: { collector_number: params[:collector_number] })
      end

      if params[:condition].present?
        scope = scope.where(condition: params[:condition])
      end

      if params[:inventory_location_id].present?
        scope = scope.where(inventory_location_id: params[:inventory_location_id])
      end

      scope
    end
  end
end
 
