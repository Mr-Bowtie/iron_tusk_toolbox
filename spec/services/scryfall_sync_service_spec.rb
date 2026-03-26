require "rails_helper"

RSpec.describe ScryfallSyncService do
  describe "#streamer_options" do
    it "falls back to the default parser when yajl is unavailable" do
      service = described_class.new
      io = StringIO.new("[]")

      allow(service).to receive(:require).with("yajl/ffi").and_raise(LoadError, "missing yajl")
      allow(Rails.logger).to receive(:warn)

      options = service.send(:streamer_options, io)

      expect(options).to eq(file_io: io, chunk_size: 1024)
      expect(Rails.logger).to have_received(:warn).with(/missing yajl/)
    end
  end
end
