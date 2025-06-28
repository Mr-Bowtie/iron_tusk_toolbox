namespace :scryfall do
  desc "Sync card data from Scryfall API"
  task sync: :environment do
    puts "Starting Scryfall data sync..."
    
    begin
      ScryfallDataSyncJob.perform_now
      puts "✅ Scryfall sync completed successfully!"
    rescue => e
      puts "❌ Scryfall sync failed: #{e.message}"
      puts e.backtrace.join("\n") if Rails.env.development?
      exit 1
    end
  end
  
  desc "Force sync card data from Scryfall API (ignores timing checks)"
  task force_sync: :environment do
    puts "Starting forced Scryfall data sync..."
    
    begin
      ScryfallDataSyncJob.perform_now(force_update: true)
      puts "✅ Forced Scryfall sync completed successfully!"
    rescue => e
      puts "❌ Forced Scryfall sync failed: #{e.message}"
      puts e.backtrace.join("\n") if Rails.env.development?
      exit 1
    end
  end
  
  desc "Show Scryfall sync status"
  task status: :environment do
    status = SyncStatus.find_by(sync_type: 'scryfall_cards')
    
    if status.nil?
      puts "❓ No sync has been performed yet"
      puts "Run: rake scryfall:sync"
    else
      puts "📊 Scryfall Sync Status:"
      puts "Last synced: #{status.last_synced_at}"
      puts "Details: #{status.sync_details_hash}"
      puts "Cards in database: #{CardMetadatum.count}"
      
      if status.last_synced_at < 25.hours.ago
        puts "⚠️  Data is outdated (>24 hours old)"
        puts "Consider running: rake scryfall:sync"
      else
        puts "✅ Data is up to date"
      end
    end
  end
  
  desc "Clean up old/invalid card data"
  task cleanup: :environment do
    puts "Starting Scryfall data cleanup..."
    
    # Remove cards with invalid scryfall_ids
    invalid_count = CardMetadatum.where(scryfall_id: [nil, ""]).delete_all
    puts "Removed #{invalid_count} cards with invalid scryfall_ids"
    
    # Remove duplicate cards (keeping the most recent)
    duplicates = CardMetadatum.select(:scryfall_id)
                              .group(:scryfall_id)
                              .having('count(*) > 1')
                              .count
    
    if duplicates.any?
      puts "Found #{duplicates.size} duplicate scryfall_ids"
      duplicates.each do |scryfall_id, count|
        # Keep the most recent, delete the rest
        cards = CardMetadatum.where(scryfall_id: scryfall_id).order(:updated_at)
        cards[0...-1].each(&:destroy)
        puts "Cleaned up #{count - 1} duplicates for #{scryfall_id}"
      end
    end
    
    puts "✅ Cleanup completed"
  end
end