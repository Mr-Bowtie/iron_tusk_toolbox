class CsvParser
  def self.parse(file_path, headers: true)
    Enumerator.new do |yielder|
      CSV.foreach(file_path, headers: headers) do |row|
        yielder << row
      end
    end
  end
end
