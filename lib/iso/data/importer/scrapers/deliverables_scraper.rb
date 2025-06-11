# lib/iso/data/importer/scrapers/deliverables_scraper.rb
# frozen_string_literal: true

require_relative 'base_scraper'
require_relative '../models/deliverable'

module Iso
  module Data
    module Importer
      module Scrapers
        class DeliverablesScraper < BaseScraper
          SOURCE_URL = "https://isopublicstorageprod.blob.core.windows.net/opendata/_latest/iso_deliverables_metadata/json/iso_deliverables_metadata.jsonl"
          LOCAL_FILENAME = "iso_deliverables_metadata.jsonl"

          def scrape(force_download: false, &block)
            # Uncomment for deep debugging if needed:
            # puts "SCRAPE METHOD ENTERED for DeliverablesScraper"
            # puts "  force_download: #{force_download}"
            # puts "  Block given? #{block_given?}"

            log("Starting scrape for ISO Deliverables...", 0, :info)
            processed_count = 0 # Initialize early, will be returned

            downloaded_file_path = download_file(
              SOURCE_URL,
              LOCAL_FILENAME,
              force_download: force_download
            )

            unless downloaded_file_path && File.exist?(downloaded_file_path)
              log("Failed to download or find deliverables file. Aborting scrape.", 0, :error)
              # puts "  RETURNING from scrape due to download failure. Count: #{processed_count}" # Debug
              return processed_count # Will be 0
            end

            begin
              # puts "  Attempting to process file: #{downloaded_file_path}" # Debug
              each_jsonl_item(downloaded_file_path) do |json_hash|
                begin
                  deliverable = Iso::Data::Importer::Models::Deliverable.new(json_hash)
                  yield deliverable # Call the block passed to scrape (e.g., from RSpec)
                  processed_count += 1
                rescue ArgumentError => e # Typically from Model.new if data is bad for attributes
                  log("Error instantiating Deliverable model: #{e.message}", 1, :warn)
                  log("Problematic JSON data snippet: #{json_hash.inspect[0..250]}...", 2, :warn)
                rescue StandardError => e # Other errors during single item processing
                  log("Unexpected error processing a deliverable item: #{e.class} - #{e.message}", 1, :error)
                  log("Item data snippet: #{json_hash.inspect[0..250]}...", 2, :error)
                  log("Backtrace (item processing):\n#{e.backtrace.take(5).join("\n")}", 2, :error)
                end
              end
              # puts "  Finished each_jsonl_item loop. Current processed_count: #{processed_count}" # Debug
            rescue StandardError => e # For critical errors from each_jsonl_item itself (e.g., file IO)
              log("Critical error during JSONL processing for deliverables: #{e.message}", 0, :error)
              log("Backtrace (JSONL processing):\n#{e.backtrace.take(5).join("\n")}", 1, :error)
              # processed_count will hold its value before this critical error (e.g., 0 if it failed early)
              # The method will then proceed to the final log and return.
            end

            log("Finished scraping ISO Deliverables. Processed #{processed_count} items.", 0, :info)
            # puts "  FINAL RETURN from scrape. Count: #{processed_count}" # Debug
            return processed_count # Explicit final return
          end
        end
      end
    end
  end
end