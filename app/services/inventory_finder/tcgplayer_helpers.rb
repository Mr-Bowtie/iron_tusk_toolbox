module InventoryFinder::TcgplayerHelpers
    def set_name_converter(name)
      if name.include?("FANTASY")
        name = name.split(" ").map { |n| n.downcase.capitalize }.join(" ")
      end

      if name.include?("Commander: Kamigawa")
        name = "Neon Dynasty Commander"
      end

      if name.include?("Commander:")
        name = name.gsub("Commander: ", "") + " Commander"
      end

      if name == "The List Reprints"
        name = "The List"
      end

      if name.include?("Breaking News")
        name = "Breaking News"
      end

      if name.include?("The Big Score")
        name = "The Big Score"
      end


      if name.include?("Free-For-All")
        name = "Game Night: Free-for-All"
      end

      if name.include?("Universes Beyond:")
        name = name.gsub("Universes Beyond: ", "")
      end

      if name.include?("Warhammer 40,000")
        name = name + " Commander"
      end

      if name == "Avatar: The Last Airbender: Eternal-Legal"
        name = "Avatar: The Last Airbender Eternal"
      end

      name
    end
end
