module Inventory
  class CardSearch
    attr_reader :params, :relation

    def initialize(params = {})
      @params = params
      @relation = relation
    end

    def results
      query_strings = []
      query_params = []

      if params[:name].present?
        string = "LOWER(card_metadata.name) LIKE ?"
        param = "%#{params[:name].downcase}%"

        query_strings << string
        query_params << param
      end

      if params[:set].present?
        string = "LOWER(card_metadata.set) LIKE ?"
        # make sure we can chain querys together 
        string = " AND " + string if query_strings.length > 0
        param = "%#{params[:set].downcase}%"

        query_strings << string
        query_params << param
      end

      if params[:collector_number].present?
        string = "card_metadata.collector_number = ?"
        string = " AND " + string if query_strings.length > 0
        param = "#{params[:collector_number]}"

        query_strings << string
        query_params << param
      end

      if params[:condition].present?
        string = "inventory_cards.condition = ?"
        string = " AND " + string if query_strings.length > 0
        param = "#{params[:condition]}"

        query_strings << string
        query_params << param
      end

      if params[:inventory_location_id].present?
        string = "inventory_locations.id = ?"
        string = " AND " + string if query_strings.length > 0
        param = "#{params[:inventory_location_id]}"

        query_strings << string
        query_params << param
      end

      return nil unless query_strings.length > 0

      query_template_string = query_strings.join
      query_params.unshift(query_template_string)
      Inventory::Card.includes(:metadata, :inventory_location).references(:metadata, :inventory_location).where(query_params).order("card_metadata.name ASC")

    end
  end
end
 
