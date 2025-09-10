module InventoryFinder::TcgplayerHelpers
  
    def set_name_converter(name)
      if name.include?("FANTASY")
        name = name.split(" ").map{|n| n.downcase.capitalize }.join(" ")
      end

      if name.include?("Commander:")
        name = name.gsub("Commander: ", "") + " Commander"
      end

      if name == "The List Reprints"
        name = "The List"
      end

      name
    end
end
