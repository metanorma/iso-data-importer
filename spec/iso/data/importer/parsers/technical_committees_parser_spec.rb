# spec/iso/data/importer/parsers/technical_committees_parser_spec.rb
require "spec_helper"

require "iso/data/importer/parsers/technical_committees_scraper"
require "iso/data/importer/models/technical_committee"

require "fileutils"
require "httparty"

RSpec.describe Iso::Data::Importer::Parsers::TechnicalCommitteesParser do
  let(:scraper) { described_class.new }

  let(:source_url) do
    Iso::Data::Importer::Parsers::TechnicalCommitteesParser::SOURCE_URL
  end
  let(:local_filename) do
    Iso::Data::Importer::Parsers::TechnicalCommitteesParser::LOCAL_FILENAME
  end
  let(:cache_dir) { Iso::Data::Importer::Parsers::BaseParser::TMP_DIR }
  let(:cache_path) { File.join(cache_dir, local_filename) }

  around(:each) do |example|
    FileUtils.mkdir_p(cache_dir) unless Dir.exist?(cache_dir)
    FileUtils.rm_f(cache_path)
    example.run
    FileUtils.rm_f(cache_path)
  end

  describe "#download" do
    it "downloads the JSONL file, parses it, and yields TechnicalCommittee objects",
       :live do
      committees_yielded = []
      allow(scraper).to receive(:log).and_call_original
      exception_in_yield_block = nil

      scraper.download(force_download: true) do |committee|
        expect(committee).to be_an_instance_of(Iso::Data::Importer::Models::TechnicalCommittee)
        if committee.respond_to?(:id) && !committee.id.nil?
          expect(committee.id).to be_a(Integer)
        end
        committees_yielded << committee
        break if committees_yielded.count >= 2
      rescue StandardError => e
        exception_in_yield_block = e
        # Optional: Add puts here for debugging if this block is unexpectedly hit
        # puts "\nDEBUG SPEC (TC Scraper - LIVE YIELD BLOCK): Exception caught: #{e.inspect}"
        break
      end

      expect(exception_in_yield_block).to be_nil,
                                          "Test failed due to an exception inside the yielded block: #{exception_in_yield_block&.inspect}"

      expect(File.exist?(cache_path)).to be true
      expect(File.size(cache_path)).to be > 0
      expect(committees_yielded.count).to eq(2),
                                          "Expected to yield exactly 2 committees due to break"
      # The return value of download when 'break' is used in the yielded block is nil.
      # We test the actual processed_count return in the malformed_jsonl test where the loop completes.
    end

    it "uses a cached file if force_download is false and the file exists" do
      # 1. Populate cache
      allow(scraper).to receive(:log).and_call_original # Allow all logs during setup
      # Ensure download
      scraper.download(force_download: true) do |model|
        break if model
      end
      expect(File.exist?(cache_path)).to be true
      original_mtime = File.mtime(cache_path)
      original_size = File.size(cache_path)
      sleep(1.1) # For mtime comparison

      # 2. Expect no new HTTP GET and specific log order for cache usage
      expect(HTTParty).not_to receive(:get).with(source_url, anything)

      # Corrected order of log expectations:
      expect(scraper).to receive(:log).with(/Starting download for ISO Technical Committees/i, 0, :info).ordered # This comes first
      expect(scraper).to receive(:log).with("Using cached file: #{cache_path}", 0, :info).ordered # Then this from download_file
      # Allow other subsequent logs (like Parsed items, Finished scraping) to pass without strict order after these two.
      allow(scraper).to receive(:log).with(anything, anything,
                                           anything).and_call_original

      scraper.download(force_download: false) { |model| break if model }

      expect(File.mtime(cache_path).to_i).to eq(original_mtime.to_i)
      expect(File.size(cache_path)).to eq(original_size)
    end

    it "handles download errors gracefully and logs them" do
      allow(HTTParty).to receive(:get)
        .with(source_url, hash_including(stream_body: true))
        .and_raise(Timeout::Error.new("Simulated Timeout::Error from RSpec"))

      expect(scraper).to receive(:log).with(
        "Starting download for ISO Technical Committees...", 0, :info
      ).ordered
      expect(scraper).to receive(:log).with(
        "Downloading #{local_filename} from #{source_url}...", 0, :info
      ).ordered
      expect(scraper).to receive(:log).with(
        /Exception downloading #{Regexp.escape(local_filename)}: Timeout::Error - Simulated Timeout::Error/i, 1, :error
      ).ordered
      expect(scraper).to receive(:log).with(
        "Failed to download or find technical committees file. Aborting download.", 0, :error
      ).ordered

      processed_count = # Yielded block not strictly necessary for this test
        scraper.download(force_download: true) do
        end
      expect(processed_count).to eq(0)
    end

    context "when processing a cached file with a malformed JSONL line" do
      before do
        File.write(cache_path,
                   "{\"id\":1000,\"reference\":\"TC GOOD\"}\nthis_is_not_json\n{\"id\":2000,\"reference\":\"TC ALSO GOOD\"}")
      end

      it "skips the malformed line, logs a warning, and processes valid lines" do
        yielded_objects = []

        expect(scraper).to receive(:log).with(
          "Starting download for ISO Technical Committees...", 0, :info
        ).ordered
        expect(scraper).to receive(:log).with(
          "Using cached file: #{cache_path}", 0, :info
        ).ordered
        expect(scraper).to receive(:log).with(
          /Skipping invalid JSON line 2.*this_is_not_json/i, 1, :warn
        ).ordered
        expect(scraper).to receive(:log).with(
          a_string_matching(/Error: unexpected token at 'this_is_not_json(\n)?'/i), 2, :warn
        ).ordered
        expect(scraper).to receive(:log).with(
          "Parsed 2 items from #{local_filename}", 0, :info
        ).ordered
        expect(scraper).to receive(:log).with(
          "Finished scraping ISO Technical Committees. Processed 2 items.", 0, :info
        ).ordered

        processed_count = scraper.download(force_download: false) do |committee|
          yielded_objects << committee
        end

        expect(processed_count).to eq(2) # This tests the actual return value when download completes
        expect(yielded_objects.map(&:id)).to contain_exactly(1000, 2000)
      end
    end
  end
end
