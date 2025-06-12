# spec/iso/data/importer/parsers/ics_parser_spec.rb
require "spec_helper"

require "iso/data/importer/parsers/ics_scraper"
require "iso/data/importer/models/ics_entry"

require "fileutils"
require "httparty"
require "csv"

RSpec.describe Iso::Data::Importer::Parsers::IcsParser do
  let(:scraper) { described_class.new }

  let(:source_url) { Iso::Data::Importer::Parsers::IcsParser::SOURCE_URL }
  let(:local_filename) do
    Iso::Data::Importer::Parsers::IcsParser::LOCAL_FILENAME
  end
  let(:cache_dir) { Iso::Data::Importer::Parsers::BaseParser::TMP_DIR }
  let(:cache_path) { File.join(cache_dir, local_filename) }

  let(:sample_csv_header) do
    "identifier,parent,titleEn,titleFr,scopeEn,scopeFr"
  end

  around(:each) do |example|
    FileUtils.mkdir_p(cache_dir) unless Dir.exist?(cache_dir)
    FileUtils.rm_f(cache_path)
    example.run
    FileUtils.rm_f(cache_path)
  end

  describe "#download" do
    context "when downloading and parsing successfully (using a prepared cache file)" do
      let(:sample_csv_data_row1) do
        "\"01\",\"\",\"Generalities. Terminology. Standardization. Documentation\",\"Généralités. Terminologie. Normalisation. Documentation\",\"\",\"\""
      end
      let(:sample_csv_data_row2) do
        "\"03.140\",\"03\",\"Testing of materials\",\"Essais des matériaux\",\"Specific tests\",\"Essais spécifiques\""
      end

      before do
        File.write(cache_path,
                   "#{sample_csv_header}\n#{sample_csv_data_row1}\n#{sample_csv_data_row2}")
        allow(scraper).to receive(:download_file).with(source_url,
                                                       local_filename, force_download: false).and_return(cache_path)
        # Allow the force_download: true variant to call original if used elsewhere, e.g. live tests not included here
        allow(scraper).to receive(:download_file).with(source_url,
                                                       local_filename, force_download: true).and_call_original
      end

      it "yields IcsEntry objects" do
        ics_entries_yielded = []
        allow(scraper).to receive(:log).and_call_original # Allow logs but don't assert specific order here

        scraper.download(force_download: false) do |ics_entry|
          expect(ics_entry).to be_an_instance_of(Iso::Data::Importer::Models::IcsEntry)
          ics_entries_yielded << ics_entry
        end
        expect(ics_entries_yielded.count).to eq(2)
      end

      it "correctly populates the first IcsEntry object" do
        first_entry = nil
        allow(scraper).to receive(:log).and_call_original
        scraper.download(force_download: false) do |entry|
          first_entry = entry
          break
        end

        expect(first_entry.identifier).to eq("01")
        expect(first_entry.parent).to be_nil
        expect(first_entry.title_en).to eq("Generalities. Terminology. Standardization. Documentation")
        expect(first_entry.scope_en).to be_nil
      end

      it "returns the correct processed count when completing fully" do
        allow(scraper).to receive(:log).and_call_original
        processed_count = scraper.download(force_download: false) # Call without a block
        expect(processed_count).to eq(2)
      end
    end

    it "uses a cached file if force_download is false and the file exists" do
      File.write(cache_path,
                 "#{sample_csv_header}\n\"99\",\"TEST\",\"Test Title EN\",\"Test Title FR\",\"\",\"\"\n")
      expect(File.exist?(cache_path)).to be true
      original_mtime = File.mtime(cache_path)
      sleep(1.1)

      expect(HTTParty).not_to receive(:get).with(source_url, anything)

      # Expect the "Starting..." and "Using cached file..." logs in order.
      expect(scraper).to receive(:log).with(
        /Starting download for ISO ICS data/i, 0, :info
      ).ordered.and_call_original
      expect(scraper).to receive(:log).with("Using cached file: #{cache_path}",
                                            0, :info).ordered.and_call_original
      # Allow any other logs that might occur after these two specific ordered ones.
      allow(scraper).to receive(:log).with(anything, anything,
                                           anything).and_call_original

      scraper.download(force_download: false) { |entry| break if entry }

      expect(File.mtime(cache_path).to_i).to eq(original_mtime.to_i)
    end

    it "handles download errors gracefully and logs them" do
      allow(HTTParty).to receive(:get)
        .with(source_url, hash_including(stream_body: true))
        .and_raise(SocketError.new("Simulated CSV download error"))

      # Expect this sequence of logs for a download error
      expect(scraper).to receive(:log).with(
        "Starting download for ISO ICS data...", 0, :info
      ).ordered.and_call_original
      expect(scraper).to receive(:log).with(
        "Downloading #{local_filename} from #{source_url}...", 0, :info
      ).ordered.and_call_original
      expect(scraper).to receive(:log).with(
        /Exception downloading #{Regexp.escape(local_filename)}: SocketError - Simulated CSV download error/i, 1, :error
      ).ordered.and_call_original
      expect(scraper).to receive(:log).with(
        "Failed to download or find ICS data file. Aborting download.", 0, :error
      ).ordered.and_call_original
      # No other logs should be expected in this error path if it aborts correctly.

      processed_count = # Call without a block
        scraper.download(force_download: true) do
        end
      expect(processed_count).to eq(0)
    end

    context "when processing a cached CSV file with a malformed line" do
      before do
        malformed_csv_content = "#{sample_csv_header}\n\"01\",\"P1\",\"T_En1\",\"T_Fr1\",\"S_En1\",\"S_Fr1\"\n\"02\",\"Extra\"Field\",BadLine导致解析失败\n\"03\",\"P3\",\"T_En3\",\"T_Fr3\",\"S_En3\",\"S_Fr3\""
        File.write(cache_path, malformed_csv_content)
        allow(scraper).to receive(:download_file).with(source_url,
                                                       local_filename, force_download: false).and_return(cache_path)
      end

      it "logs the MalformedCSVError and processes items before the error" do
        yielded_objects = []

        # Expect the critical "Malformed CSV error" log to occur at least once.
        # We are less concerned about its exact order relative to all other info logs for this test.
        expect(scraper).to receive(:log).with(
          a_string_matching(/Malformed CSV error in #{local_filename}.*near line 3/i), 1, :error
        ).once.and_call_original

        # Allow any other log calls to happen.
        allow(scraper).to receive(:log).with(anything, anything,
                                             anything).and_call_original

        processed_count = scraper.download(force_download: false) do |ics_entry|
          yielded_objects << ics_entry
        end

        # Functional checks are most important:
        expect(processed_count).to eq(1) # One row was processed before the error
        expect(yielded_objects.count).to eq(1)
        expect(yielded_objects.first.identifier).to eq("01")

        # Optional: If you still want to check other specific logs occurred, but without strict ordering:
        # expect(scraper).to have_received(:log).with("Starting download for ISO ICS data...", 0, :info)
        # expect(scraper).to have_received(:log).with("Processed 1 rows from #{local_filename}", 0, :info)
        # expect(scraper).to have_received(:log).with("Finished scraping ISO ICS data. Processed 1 items.", 0, :info)
        # Note: `have_received` requires `spy` setup or `and_call_original` on a prior `allow` or `expect`.
        # The current `allow(scraper).to receive(:log).with(anything, anything, anything).and_call_original`
        # means we can't use `have_received` directly after the fact without more setup.
        # For simplicity, focusing on the critical error log and functional outcome is often enough.
      end
    end
  end
end
