module InventoryImporter
  class Base
    def initialize(row)
      @row = row
    end

    def import!
      raise NotImplementedError
    end
  end
end


