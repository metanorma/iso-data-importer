# spec/iso/data/importer/scrapers/deliverables_scraper_spec.rb
require "spec_helper"

require "iso/data/importer/scrapers/deliverables_scraper"
require "iso/data/importer/models/deliverable"

require "fileutils"
require "httparty"

RSpec.describe Iso::Data::Importer::Scrapers::DeliverablesScraper do
  let(:scraper) { described_class.new }

  let(:source_url) { "https://isopublicstorageprod.blob.core.windows.net/opendata/_latest/iso_deliverables_metadata/json/iso_deliverables_metadata.jsonl" }
  let(:local_filename) { "iso_deliverables_metadata.jsonl" }
  let(:cache_dir) { Iso::Data::Importer::Scrapers::BaseScraper::TMP_DIR }
  let(:cache_path) { File.join(cache_dir, local_filename) }

  around(:each) do |example|
    FileUtils.mkdir_p(cache_dir) unless Dir.exist?(cache_dir)
    FileUtils.rm_f(cache_path)
    example.run
    FileUtils.rm_f(cache_path)
  end

  describe "#scrape" do
    it "downloads the JSONL file, parses it, and yields Deliverable objects",
       :live do
      deliverables_yielded = []
      allow(scraper).to receive(:log).and_call_original # Allow all logs
      exception_in_yield_block = nil # Flag for errors in the spec's block

      processed_count = scraper.scrape(force_download: true) do |deliverable|
        # --- Start: Code within the block passed to scraper.scrape ---
        expect(deliverable).to be_an_instance_of(Iso::Data::Importer::Models::Deliverable)

        # Safer check for deliverable.id before type assertion
        if deliverable.respond_to?(:id) && !deliverable.id.nil?
          expect(deliverable.id).to be_a(Integer)
        elsif deliverable.respond_to?(:id) && deliverable.id.nil?
          # This is acceptable if ID can be null from source and model allows it
        else
          # This would be unexpected if id attribute should always exist
          # puts "WARN: Deliverable object does not have an 'id' or it's not nil/Integer: #{deliverable.inspect}"
        end

        deliverables_yielded << deliverable
        break if deliverables_yielded.count >= 2 # Process a few for speed
        # --- End: Code within the block passed to scraper.scrape ---
      rescue StandardError => e
        exception_in_yield_block = e
        puts "\nDEBUG SPEC: Exception caught inside RSpec's yield block:"
        puts "  Class: #{e.class}"
        puts "  Message: #{e.message}"
        puts "  Backtrace (top 5):"
        e.backtrace.first(5).each { |line| puts "    #{line}" }
        break # Stop processing further items if an error occurs here
      end

      # Fail the test explicitly if the spec's own block had an error
      expect(exception_in_yield_block).to be_nil,
                                          "Test failed due to an exception inside the yielded block: #{exception_in_yield_block&.inspect}"

      expect(File.exist?(cache_path)).to be true
      expect(File.size(cache_path)).to be > 0
      expect(processed_count).to be_an(Integer),
                                 "Expected processed_count to be an Integer, got #{processed_count.inspect}"
      expect(processed_count).to be >= deliverables_yielded.count
      expect(deliverables_yielded.count).to be > 0,
                                            "Expected to yield at least one deliverable object"
    end

    it "uses a cached file if force_download is false and the file exists" do
      allow(scraper).to receive(:log).and_call_original # Allow logs during setup
      # Populate cache
      scraper.scrape(force_download: true) do |model|
        break if model
      end
      expect(File.exist?(cache_path)).to be true
      original_mtime = File.mtime(cache_path)
      original_size = File.size(cache_path)
      sleep(1.1) # For mtime comparison

      expect(HTTParty).not_to receive(:get).with(source_url, anything)

      expect(scraper).to receive(:log).with("Using cached file: #{cache_path}",
                                            0, :info).ordered.and_call_original
      # Allow other info logs
      allow(scraper).to receive(:log).with(/Starting scrape/i, 0, :info).ordered.and_call_original # Ordered with Using cached
      allow(scraper).to receive(:log).with(/Parsed \d+ items/i, 0,
                                           :info).and_call_original
      allow(scraper).to receive(:log).with(/Finished scraping/i, 0,
                                           :info).and_call_original

      scraper.scrape(force_download: false) { |model| break if model }

      expect(File.mtime(cache_path).to_i).to eq(original_mtime.to_i)
      expect(File.size(cache_path)).to eq(original_size)
    end

    it "handles download errors gracefully and logs them" do
      allow(HTTParty).to receive(:get)
        .with(source_url, hash_including(stream_body: true))
        .and_raise(SocketError.new("Simulated SocketError from RSpec"))

      expect(scraper).to receive(:log).with(
        "Starting scrape for ISO Deliverables...", 0, :info
      ).ordered.and_call_original
      expect(scraper).to receive(:log).with(
        "Downloading #{local_filename} from #{source_url}...", 0, :info
      ).ordered.and_call_original
      expect(scraper).to receive(:log).with(
        /Exception downloading #{Regexp.escape(local_filename)}: SocketError - Simulated SocketError/i, 1, :error
      ).ordered.and_call_original
      expect(scraper).to receive(:log).with(
        "Failed to download or find deliverables file. Aborting scrape.", 0, :error
      ).ordered.and_call_original
      # Ensure no other unexpected error logs, but allow info/warn if any were defined for other paths not hit

      processed_count = scraper.scrape(force_download: true) {}
      expect(processed_count).to eq(0)
    end

    context "when processing a cached file with a malformed JSONL line" do
      before do
        File.write(cache_path,
                   "{\"id\":789,\"deliverableType\":\"IS\"}\nnot_a_valid_json_line\n{\"id\":101,\"deliverableType\":\"TS\"}")
      end

      it "skips the malformed line, logs a warning, and processes valid lines" do
        yielded_objects = []

        expect(scraper).to receive(:log).with(
          "Starting scrape for ISO Deliverables...", 0, :info
        ).ordered.and_call_original
        expect(scraper).to receive(:log).with(
          "Using cached file: #{cache_path}", 0, :info
        ).ordered.and_call_original
        expect(scraper).to receive(:log).with(
          /Skipping invalid JSON line 2.*not_a_valid_json_line/i, 1, :warn
        ).ordered.and_call_original
        expect(scraper).to receive(:log).with(
          a_string_matching(/Error: unexpected token at 'not_a_valid_json_line(\n)?'/i), 2, :warn
        ).ordered.and_call_original
        expect(scraper).to receive(:log).with(
          "Parsed 2 items from #{local_filename}", 0, :info
        ).ordered.and_call_original
        expect(scraper).to receive(:log).with(
          "Finished scraping ISO Deliverables. Processed 2 items.", 0, :info
        ).ordered.and_call_original

        processed_count = scraper.scrape(force_download: false) do |deliverable|
          yielded_objects << deliverable
        end

        expect(processed_count).to eq(2)
        expect(yielded_objects.map(&:id)).to contain_exactly(789, 101)
      end
    end
  end
end
