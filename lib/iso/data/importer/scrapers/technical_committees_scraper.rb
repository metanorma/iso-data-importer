# lib/iso/data/importer/scrapers/technical_committees_scraper.rb
# frozen_string_literal: true

require_relative 'base_scraper'
require_relative '../models/technical_committee' # Corrected model name

module Iso
  module Data
    module Importer
      module Scrapers
        class TechnicalCommitteesScraper < BaseScraper
          SOURCE_URL = "https://isopublicstorageprod.blob.core.windows.net/opendata/_latest/iso_technical_committees/json/iso_technical_committees.jsonl"
          LOCAL_FILENAME = "iso_technical_committees.jsonl"

          def scrape(force_download: false, &block)
            log("Starting scrape for ISO Technical Committees...", 0, :info)
            processed_count = 0 # Initialize early, this will be the return value

            downloaded_file_path = download_file(
              SOURCE_URL,
              LOCAL_FILENAME,
              force_download: force_download
            )

            unless downloaded_file_path && File.exist?(downloaded_file_path)
              log("Failed to download or find technical committees file. Aborting scrape.", 0, :error)
              return processed_count # Explicitly return 0 (current value of processed_count)
            end

            begin
              each_jsonl_item(downloaded_file_path) do |json_hash|
                begin
                  committee = Iso::Data::Importer::Models::TechnicalCommittee.new(json_hash)
                  yield committee
                  processed_count += 1
                rescue ArgumentError => e
                  log("Error instantiating TechnicalCommittee model: #{e.message}", 1, :warn)
                  log("Problematic JSON data snippet: #{json_hash.inspect[0..250]}...", 2, :warn)
                rescue StandardError => e # Catch other errors during single item processing
                  log("Unexpected error processing a technical committee item: #{e.class} - #{e.message}", 1, :error)
                  log("Item data snippet: #{json_hash.inspect[0..250]}...", 2, :error)
                  log("Backtrace (item processing):\n#{e.backtrace.take(5).join("\n")}", 2, :error)
                end
              end
            rescue StandardError => e # For critical errors from each_jsonl_item itself (e.g., file IO)
              log("Critical error during JSONL processing for technical committees: #{e.message}", 0, :error)
              log("Backtrace (JSONL processing):\n#{e.backtrace.take(5).join("\n")}", 1, :error)
              # Even if a critical error happens here, processed_count will hold its value
              # The method will then proceed to the final log and return.
            end

            log("Finished scraping ISO Technical Committees. Processed #{processed_count} items.", 0, :info)
            return processed_count # Ensure this is the absolute last thing, guaranteeing an integer return
          end
        end
      end
    end
  end
end