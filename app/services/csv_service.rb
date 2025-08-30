class CsvService < ApplicationService
  SUPPORTED_FORMATS = {
    "manabox" => InventoryImporter::Manabox
  }.freeze

  def self.stage_import(import, format)
    importer_class = SUPPORTED_FORMATS[format]
    raise ArgumentError, "Unsupported format: #{format}" unless importer_class

    process_streamed_csv(import.path, importer_class)
  end

  def self.process_streamed_csv(file_path, importer_class, thread_count: 4, batch_size: 1000)
    work_queue = Queue.new
    threads = []

    # TODO: refactor to use background jobs for large imports
    thread_count.times do
      threads << Thread.new do
        while (batch = work_queue.pop) != :END
          batch.each do |row|
            importer_class.new(row).import!
          end
        end
      end
    end

    batch = []
    CsvParser.parse(file_path).each do |row|
      # TODO: refactor to have bad row checker
      next if row["Name"].nil?
      batch << row
      if batch.size >= batch_size
        work_queue << batch
        batch = []
      end
    end
    work_queue << batch unless batch.empty?

    thread_count.times { work_queue << :END }
    threads.each(&:join)
  end
end
